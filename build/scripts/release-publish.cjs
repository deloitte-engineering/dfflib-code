// =============================================================================
// release-publish.cjs - Publish a merged release PR, as one idempotent call
// =============================================================================
// publishRelease() promotes the recorded beta builds of a merged release PR (one per package,
// the standalone package first), tags the merge commit vX.Y.Z, publishes the GitHub Release
// `D'fflib vX.Y.Z` with the effective release notes and swaps `autorelease: pending` for `autorelease: tagged` (release-please
// opens no new release PR while a merged one still has pending). Each step is probed
// first and skipped when done, so a second call finishes a partial release and a
// complete one is a no-op. Everything that can refuse is decided before promote, so a
// refusal changes nothing. The override box is read once, at the start: the text read is
// the text published. It never builds a package version.
// Adapters: github (Octokit; tags are listed, read and created through it) and devHub
// (release-devhub.cjs). The notes come from notesFor() of
// release-notes.cjs. Called by the merge workflow and resume.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { BOX_STATE, INVALID_REASON, readBox } = require('./release-box.cjs');
const { RELEASE_TAGGED_LABEL, listLabelNames } = require('./release-label.cjs');
const { RELEASE_PR_LABEL, fromThisRepo } = require('./release-pr.cjs');
const { contentTagGuard, githubReads, readProjectText, recordedBetaBuild } = require('./release-record.cjs');
const { contentTag } = require('./release-content-tag.cjs');
const { standaloneFirst } = require('./release-package-set.cjs');
const { notesFor, fenceFor, plainText, listTagNames } = require('./release-notes.cjs');
const { isPrerelease, makeLatest, parseReleaseTag, buildCheckFailures } = require('./release-rules.cjs');

const STATUS = Object.freeze({ REFUSED: 'refused', FAILED: 'failed', PUBLISHED: 'published', COMPLETE: 'complete' });

const INVALID_BOX = {
  [INVALID_REASON.INSUFFICIENT_ROLE]: 'was last edited by someone without the maintain or admin role',
  [INVALID_REASON.EDITOR_UNKNOWN]: 'has no known last editor',
};

// The GitHub Release of `tag`, or null when there is none.
async function findRelease({ github, owner, repo }, tag) {
  try {
    return (await github.rest.repos.getReleaseByTag({ owner, repo, tag })).data;
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

// The commit the tag points at, or null when there is no such tag (404). It reads the ref, so an
// annotated tag gives its tag object, never a commit: publish then refuses it as a tag at another
// commit (safe; every tag here is lightweight). Any other error is thrown, never read as no tag.
async function readTag({ github, owner, repo }, name) {
  try {
    return (await github.rest.git.getRef({ owner, repo, ref: `tags/${name}` })).data.object.sha;
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

// A lightweight tag at `sha`. A tag that already exists (422 "Reference already exists": a retry, or a
// concurrent run) is reported, never moved; every other error, including any other 422 (such as
// an unknown commit), is thrown.
async function createTag({ github, owner, repo }, name, sha) {
  try {
    await github.rest.git.createRef({ owner, repo, ref: `refs/tags/${name}`, sha });
  } catch (error) {
    if (error.status === 422 && /already exists/i.test(error.message)) return { status: 'exists' };
    throw error;
  }
  return { status: 'created' };
}

// Removing a label a concurrent run already removed is not a failure.
async function removeLabel({ github, owner, repo, prNumber }, name) {
  try {
    await github.rest.issues.removeLabel({ owner, repo, issue_number: prNumber, name });
  } catch (error) {
    if (error.status !== 404) throw error;
  }
}

// The run summary. The published text is untrusted: fenced, never logged.
function renderSummary({ prNumber, tag, status, message, steps, box, effective, warnings }) {
  const lines = [`### Publish${tag ? ` ${tag}` : ''} - PR #${prNumber}`, '', `**${status}**: ${message}`];
  const entries = Object.entries(steps);
  if (entries.length > 0) lines.push('', ...entries.map(([step, result]) => `- ${step}: ${result}`));
  if (effective) {
    const link = box.url ? `[override box](${box.url})` : '';
    const source = effective.source === 'override' ? `the text of the ${link}, last edited by @${box.editor}`
      : link ? `generated (the ${link} is empty)` : 'generated (no override box)';
    lines.push('', `Release notes: ${source}.`);
  }
  if (warnings.length > 0) lines.push('', '#### Warnings', '', ...warnings.map((warning) => `- ${warning}`));
  if (effective) {
    const fence = fenceFor(effective.text);
    lines.push('', '#### Published release notes (full text)', '', `${fence}markdown`, effective.text, fence);
  }
  return `${lines.join('\n')}\n`;
}

const refusalMessage = (reason, next) => `${reason}. Nothing was changed. ${next}.`;

// The GitHub-only gate of a publish: the PR is merged, a release PR, from this repository and merged
// into `defaultBranch`. It reads GitHub only (no Dev Hub), so the workflow runs it before the Dev Hub
// login and publishRelease runs the same gate again. Returns { ok: true, pr, labels } or
// { ok: false, message } where message is the refusal text of publishRelease. `defaultBranch` is
// required (the workflow passes the repository's, never the dispatch input): a missing or empty
// value throws, so the base gate cannot be skipped silently. An API failure throws.
async function checkPublishable({ github, owner, repo, prNumber, defaultBranch }) {
  if (typeof defaultBranch !== 'string' || defaultBranch.trim() === '') throw new Error('publish needs the default branch of the repository');
  const refused = (reason, next) => ({ ok: false, message: refusalMessage(reason, next) });
  const { data: pr } = await github.rest.pulls.get({ owner, repo, pull_number: prNumber });
  if (pr.merged !== true) return refused(`PR #${prNumber} is not merged`, 'Publish runs once it is merged');
  const labels = await listLabelNames({ github, owner, repo, prNumber });
  if (!labels.includes(RELEASE_PR_LABEL) && !labels.includes(RELEASE_TAGGED_LABEL)) {
    return refused(`PR #${prNumber} is not a release PR (no "${RELEASE_PR_LABEL}" or "${RELEASE_TAGGED_LABEL}" label)`, 'Run publish on a merged release PR');
  }
  if (!fromThisRepo(pr, { owner, repo })) return refused(`PR #${prNumber} comes from a fork`, 'A release PR comes from this repository; nothing is published from a fork');
  if (pr.base.ref !== defaultBranch) {
    return refused(`PR #${prNumber} was merged into "${plainText(pr.base.ref)}", not into the default branch "${defaultBranch}"`, 'Only a release PR merged into the default branch is published');
  }
  return { ok: true, pr, labels };
}

// Publish the merged release PR `prNumber`, idempotently. Steps, in order: promote the
// recorded beta builds (each only if it is not promoted yet), tag the merge commit, create
// the GitHub Release, swap the labels (tagged added before pending is removed, so a crash
// leaves both, never neither).
// Refuses, changing nothing and saying how to recover, when: the PR is not merged or not
// a release PR, it comes from a fork (or its head repository is gone), it was merged into a
// branch other than `defaultBranch`, no beta build is recorded, the override box is
// invalid, the release tag exists at another commit, the content tag guard fails or the
// build checks (R4) fail for any package (the refusal names it; the package kind comes from
// the package set). The tag and the GitHub Release come only after every package is
// promoted: a failing promote of a later package leaves the earlier ones promoted (a partial
// release) and stops the call with status failed, and a second call finishes.
// `defaultBranch` is required (the workflow passes the repository's, never the dispatch
// input): a missing or empty value throws, so the base gate cannot be skipped silently.
// The box is read and the notes are generated only while the GitHub Release is
// missing. An API failure before promote throws (nothing changed); a failure from promote
// on stops the call with status failed, and a second call finishes the rest.
// Returns { status: 'refused' | 'failed' | 'published' | 'complete', message, steps,
// summary, warnings }: the caller fails the job on refused and failed, writes `summary` to
// the run summary and emits one warning annotation per `warnings` entry (one line each).
async function publishRelease({ github, owner, repo, prNumber, defaultBranch, devHub, log = console.log }) {
  const ctx = { github, owner, repo, prNumber };
  const steps = {};
  let tag = '';
  let box = null;
  let effective = null;
  const finish = (status, message) => {
    log(`PR #${prNumber}: publish ${status}: ${message}`);
    const warnings = effective ? effective.warnings : [];
    return { status, message, steps, warnings, summary: renderSummary({ prNumber, tag, status, message, steps, box, effective, warnings }) };
  };
  const refuse = (reason, next) => finish(STATUS.REFUSED, refusalMessage(reason, next));
  const again = (cause) => `A maintainer resolves ${cause} and runs publish again`;

  const gate = await checkPublishable({ github, owner, repo, prNumber, defaultBranch });
  if (!gate.ok) return finish(STATUS.REFUSED, gate.message);
  const { pr, labels } = gate;
  const mergeSha = pr.merge_commit_sha;
  const reads = githubReads({ github, owner, repo });
  const projectText = await readProjectText({ github, owner, repo, ref: pr.head.sha });
  const record = recordedBetaBuild(projectText);
  if (!record.recorded) return refuse(`The release PR records no beta build of ${record.version}`, again('the missing beta build'));
  tag = `v${record.version}`;
  if (!parseReleaseTag(tag)) throw new Error(`${tag} is not a release tag`);

  // Every recorded package with its Dev Hub row, in promote order. `released` is whether its
  // version is promoted. The content tag guard, the build checks (R4) and promote all work on
  // every one.
  const packages = [];
  for (const each of standaloneFirst(record.packages)) {
    const row = await devHub.readVersion(each.installId);
    packages.push({ ...each, row, released: row.isReleased });
  }
  const tagNames = await listTagNames(ctx);
  const tagSha = await readTag(ctx, tag);
  const done = {
    promote: packages.every((each) => each.released),
    tag: tagSha === mergeSha,
    release: Boolean(await findRelease(ctx, tag)),
    labels: labels.includes(RELEASE_TAGGED_LABEL) && !labels.includes(RELEASE_PR_LABEL),
  };
  if (Object.values(done).every(Boolean)) {
    Object.keys(done).forEach((step) => { steps[step] = 'already done'; });
    return finish(STATUS.COMPLETE, `${tag} is already published, nothing to do`);
  }

  if (!done.release) {
    box = await readBox(ctx);
    if (box.state === BOX_STATE.INVALID) {
      return refuse(`The override box (${box.url}) ${INVALID_BOX[box.reason]}, so its text is not published`, 'A maintainer or admin edits the box (emptied, the generated notes are published) and runs publish again');
    }
  }
  if (tagSha && tagSha !== mergeSha) return refuse(`Tag ${tag} points at ${tagSha}, not at the merge commit ${mergeSha}`, again('the misplaced tag'));
  const guard = contentTagGuard({ projectText, contentTag: await contentTag(reads, mergeSha), rows: packages.map((each) => each.row) });
  if (guard) return refuse(guard, again('the mismatch'));
  for (const built of packages) {
    const failures = buildCheckFailures(built.row, built.kind);
    if (failures.length > 0) return refuse(`Beta build ${built.installId} of ${plainText(built.package)} may not be promoted: ${failures.join(', ')}`, again('the failed build checks'));
  }

  if (!done.release) {
    ({ effective } = await notesFor({
      github, owner, repo, version: record.version, head: mergeSha, compareTo: tag, tagNames, box, log,
      builds: packages.map(({ package: name, kind, installId }) => ({ package: name, kind, installId })),
    }));
  }

  const promotedIds = () => packages.filter((built) => built.released).map((built) => built.installId);
  const work = {
    async promote() {
      const parts = [];
      for (const built of packages) {
        let promotedNow = false;
        if (!built.released) {
          try {
            await devHub.promoteVersion(built.installId);
            promotedNow = true;
          } catch (error) {
            if (error.code !== 'already-promoted') {
              throw Object.assign(new Error(`${built.installId} of ${built.package}: ${error.message}`, { cause: error }), { code: error.code });
            }
          }
          built.released = true;
        }
        parts.push(promotedNow ? `promoted ${built.installId}` : `${built.installId} already done`);
      }
      return parts.join(', ');
    },
    async tag() {
      const { status } = await createTag(ctx, tag, mergeSha);
      if (status === 'exists' && await readTag(ctx, tag) !== mergeSha) throw new Error(`${tag} was created at another commit meanwhile`);
      return `${status} at ${mergeSha}`;
    },
    async release() {
      const { data } = await github.rest.repos.createRelease({
        owner, repo, tag_name: tag, target_commitish: mergeSha, name: `D'fflib ${tag}`, body: effective.text,
        prerelease: isPrerelease(tag), make_latest: String(makeLatest(tag, tagNames)),
      });
      return `created ${data.html_url}`;
    },
    async labels() {
      if (!labels.includes(RELEASE_TAGGED_LABEL)) await github.rest.issues.addLabels({ owner, repo, issue_number: prNumber, labels: [RELEASE_TAGGED_LABEL] });
      if (labels.includes(RELEASE_PR_LABEL)) await removeLabel(ctx, RELEASE_PR_LABEL);
      return `"${RELEASE_TAGGED_LABEL}" on, "${RELEASE_PR_LABEL}" off`;
    },
  };
  const order = Object.keys(work);
  for (const [index, step] of order.entries()) {
    if (done[step]) {
      steps[step] = 'already done';
      continue;
    }
    try {
      steps[step] = await work[step]();
    } catch (error) {
      steps[step] = `failed: ${plainText(error.message)}`;
      order.slice(index + 1).forEach((later) => { steps[later] = 'not run'; });
      const promoted = step === 'promote' ? promotedIds() : [];
      const before = promoted.length > 0 ? `${promoted.join(', ')} ${promoted.length > 1 ? 'are' : 'is'} already promoted`
        : index === 0 ? 'Nothing was changed' : 'The steps before it are done';
      return finish(STATUS.FAILED, `Publish of ${tag} stopped at the ${step} step. ${before}; run publish again to finish the rest`);
    }
  }
  return finish(STATUS.PUBLISHED, `${tag} is published`);
}

module.exports = { STATUS, publishRelease, checkPublishable };
