// =============================================================================
// release-beta.cjs - Beta build logic of a release PR
// =============================================================================
// Decisions for beta-build.yml and beta-build-request.yml: whether to reuse a build,
// whether the branch records a current beta build (release-record.cjs), which
// release PR to build (release-pr.cjs decides what the release PR is) and whether
// a label request may start a build. The beta build runs in three stages (selectBetaPr and
// checkBetaPr, planBeta, buildBeta); the workflow only moves data in and out. buildBeta is
// the one call over the Dev Hub adapter (release-devhub.cjs): list, decide, create, read the
// created row. The functions that end in a GitHub API write (pushAliasCommit, requestBetaBuild)
// take the API client as an argument; selectBetaPr, checkBetaPr and planBeta are pure.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { BETA_STATE, buildNumber, differingBuilds } = require('./release-record.cjs');
const { packageSet } = require('./release-package-set.cjs');
const { buildCheckFailures } = require('./release-rules.cjs');
const { BETA_REQUEST_LABEL } = require('./release-label.cjs');
const { RELEASE_PR_LABEL, isReleasePr, fromThisRepo, selectReleasePr, checkMaintainer } = require('./release-pr.cjs');

// The GitHub REST API version the dispatch of beta-build.yml sends (X-GitHub-Api-Version).
// Without the header GitHub serves 2022-11-28, which it deprecates; the supported versions
// are listed at https://docs.github.com/en/rest/about-the-rest-api/api-versions.
const GITHUB_API_VERSION = '2026-03-10';

// Reuse or create: an unpromoted package version with the same X.Y.Z and the same
// tag (the tree hash of the built content) is reused, so a re-run never spends a
// version create. `versions` are rows of the Dev Hub adapter
// (listVersions); a promoted (released) version is never reused, nor one that fails
// the promotable rule R4 (buildCheckFailures: reuse, record and publish share it) for the
// package `kind` (PACKAGE_KIND of release-package-set.cjs; required). With several matches
// the highest build wins. Returns { action: 'create' } or { action: 'reuse', id, build }.
function decideBuild(versions, { version, tag, kind }) {
  if (!tag) return { action: 'create' };
  const prefix = `${version}.`;
  const matches = versions
    .filter((row) => row.tag === tag && !row.isReleased && buildNumber(row.version, prefix) !== null && buildCheckFailures(row, kind).length === 0)
    .map((row) => ({ id: row.id, build: buildNumber(row.version, prefix) }))
    .sort((a, b) => b.build - a.build);
  return matches.length > 0 ? { action: 'reuse', ...matches[0] } : { action: 'create' };
}

// Stage 1a of the beta build, the choice. `prs` are the open issue objects that carry
// the release PR label (issues.listForRepo with `labels`), `input` is the optional
// manual pr_number. Returns { number } (the PR to build), { notice } (none or several:
// the run ends cleanly) or { refusal } (the input is not digits: the run fails).
function selectBetaPr({ prs, input }) {
  if (input && !/^\d+$/.test(input)) return { refusal: 'pr_number must be a PR number (digits only)' };
  const { pr, notice } = selectReleasePr(prs.filter((issue) => issue.pull_request), input);
  return pr ? { number: pr.number } : { notice };
}

// Stage 1b, the check of the chosen PR as pulls.get returns it (it has the head the
// issue objects lack). Returns { number, headRef, buildSha } or { refusal } for a fork.
function checkBetaPr(pr, { owner, repo }) {
  if (!fromThisRepo(pr, { owner, repo })) return { refusal: `PR #${pr.number} comes from a fork - refusing to build it` };
  return { number: pr.number, headRef: pr.head.ref, buildSha: pr.head.sha };
}

// Stage 2, the plan. `projectText` is sfdx-project.json at the build SHA;
// `betaState` is betaBuildState of release-record.cjs for that SHA; only a current
// beta build is skipped, a stale or missing one is built (it throws without a state:
// a plan must never guess). `contentTag` is the combined content tag of the build SHA
// (contentTag of release-content-tag.cjs, one hash for every package; a skip needs none).
// Returns { skip: true, notice } when the branch records a current beta build,
// { skip: false, packages: [{ package, version, tag, kind }] } to build (one entry per package of the
// set, in file order, with its package kind; reuse or create is decided per package in buildBeta), or { refusal } for a
// tag that is not a 40-character hash.
function planBeta({ projectText, betaState, contentTag }) {
  if (betaState.state === BETA_STATE.CURRENT) {
    return { skip: true, notice: 'The release branch already records a current beta build of this version - nothing to build' };
  }
  const tag = String(contentTag ?? '').trim();
  if (!/^[0-9a-f]{40}$/.test(tag)) return { refusal: 'Could not take the content tag of the content roots' };
  return { skip: false, packages: packageSet(projectText).map((entry) => ({ package: entry.name, version: entry.baseVersion, tag, kind: entry.kind })) };
}

// An adapter call as a value: { value } or { refusal } naming the step and the adapter's
// error code (auth, not-found, failed).
async function devHubStep(name, work) {
  try {
    return { value: await work() };
  } catch (error) {
    return { refusal: `Dev Hub ${name} failed (${error.code || 'failed'}): ${error.message}` };
  }
}

// One package: list its versions, decide, reuse or create, and read the created row. A created
// version must pass the same promotable rule as a reused one (R4), else it is not recorded.
// Returns { package, version, build, installId, action } or { refusal }.
async function buildPackage(devHub, { package: packageName, version, tag, kind }) {
  const listed = await devHubStep('list', () => devHub.listVersions(packageName));
  if (listed.refusal) return listed;
  const decision = decideBuild(listed.value, { version, tag, kind });
  if (decision.action === 'reuse') return { package: packageName, version, build: decision.build, installId: decision.id, action: 'reuse' };
  const created = await devHubStep('create', () => devHub.createVersion({ package: packageName, version, tag }));
  if (created.refusal) return created;
  const read = await devHubStep('read', () => devHub.readVersion(created.value.id));
  if (read.refusal) return read;
  const failures = buildCheckFailures(read.value, kind);
  if (failures.length > 0) return { refusal: `Beta build ${created.value.id} of ${packageName} may not be recorded: ${failures.join(', ')}` };
  const build = buildNumber(read.value.version, `${version}.`);
  if (build === null) return { refusal: `Beta build ${created.value.id} is version ${read.value.version}, not a build of ${version}` };
  return { package: packageName, version, build, installId: created.value.id, action: 'create' };
}

// Stage 3, the build. `packages` is the plan's list ([{ package, version, tag, kind }]); each is
// reused or created through `devHub` (the Dev Hub adapter). The packages share X.Y.Z; each keeps its
// own BUILD number, so the numbers may differ. Returns { builds: [{ package, version, build, installId, action }],
// warning } (what push-alias records; `warning` is differingBuilds of the builds: a text or null) or { refusal };
// adapter errors are refusals too, so nothing here throws.
async function buildBeta({ devHub, packages }) {
  if (!Array.isArray(packages) || packages.length === 0) return { refusal: 'No package to build' };
  const builds = [];
  for (const item of packages) {
    const built = await buildPackage(devHub, item);
    if (built.refusal) return built;
    builds.push(built);
  }
  return { builds, warning: differingBuilds(builds) };
}

// Commit the alias file on top of `baseSha` (the branch head the build started
// from) and move the branch there, through the git data API. The ref update is
// never forced: if the branch moved meanwhile (release-please rebuilt it, or a
// person pushed) GitHub answers 422 and the build is left for the next run. A 422
// can also be a ruleset or protection rejection, so the branch is re-read: it counts
// as moved only when it no longer points at `baseSha`; otherwise the error is rethrown.
// `identity` ({ name, email }, the release token's git-user and git-email) is both
// author and committer of the commit. The commit is unsigned, so GitHub
// does not show it as verified. Returns { status: 'pushed', sha } or { status: 'branch-moved' }; other errors throw.
async function pushAliasCommit({ github, owner, repo, branch, baseSha, projectText, message, identity }) {
  if (!identity || !identity.name || !identity.email) throw new Error('pushAliasCommit needs the release token identity (name and email)');
  const person = { name: identity.name, email: identity.email };
  const { git } = github.rest;
  const base = (await git.getCommit({ owner, repo, commit_sha: baseSha })).data;
  const blob = (await git.createBlob({ owner, repo, content: projectText, encoding: 'utf-8' })).data;
  const tree = (await git.createTree({
    owner, repo, base_tree: base.tree.sha,
    tree: [{ path: 'sfdx-project.json', mode: '100644', type: 'blob', sha: blob.sha }],
  })).data;
  const commit = (await git.createCommit({
    owner, repo, message, tree: tree.sha, parents: [baseSha], author: person, committer: person,
  })).data;
  try {
    await git.updateRef({ owner, repo, ref: `heads/${branch}`, sha: commit.sha, force: false });
  } catch (error) {
    if (error.status !== 422) throw error;
    const head = (await git.getRef({ owner, repo, ref: `heads/${branch}` })).data.object.sha;
    if (head === baseSha) throw error;
    return { status: 'branch-moved' };
  }
  return { status: 'pushed', sha: commit.sha };
}

// The actor check of beta-build.yml: who may run the build. A person needs the
// Maintainer role (checkMaintainer in release-pr.cjs). A login that ends in [bot]
// is allowed without a lookup: the label path starts the build with GITHUB_TOKEN,
// so its actor is github-actions[bot].
// Returns { allowed, notice? }.
async function canStartBeta({ github, owner, repo, actor }) {
  if (String(actor).endsWith('[bot]')) return { allowed: true };
  return checkMaintainer({ github, owner, repo, login: actor });
}

// A maintainer adds the request label to the release PR to ask for a beta build.
// This turns that label event into at most one dispatch of beta-build.yml. The
// label is consumed (removed) first, before any other check, every time it is the
// request label, so adding it again asks again; it is never restored (that would
// fire `labeled` again and retry in a loop). Anything else is refused with a notice
// and no dispatch: a PR that is not an open `autorelease: pending` PR of this
// repository, or a sender below maintain. Returns { status: 'ignored' | 'refused' |
// 'dispatched', notice?, prNumber? }. A failed call throws an error that names it,
// keeps its status and cause and says what to do; the red run notifies the
// person who added the label. The label after each failure:
//   label removal (not 404)  may still be on the PR: remove it by hand, then add it again
//   label removal 404        already gone: carries on
//   role lookup, dispatch    removed, no build started: add it again
async function requestBetaBuild({ github, owner, repo, pr, labelName, sender, ref, log = console.log }) {
  if (labelName !== BETA_REQUEST_LABEL) return { status: 'ignored', notice: `"${labelName}" is not the beta build request label` };

  const callFailed = (error, call, whatToDo) => Object.assign(
    new Error(`The ${call} for PR #${pr.number} failed (${error.message}). ${whatToDo}`, { cause: error }),
    { status: error.status },
  );
  const addAgain = `The "${BETA_REQUEST_LABEL}" label was removed and no beta build was started: add "${BETA_REQUEST_LABEL}" again to retry.`;

  try {
    await github.rest.issues.removeLabel({ owner, repo, issue_number: pr.number, name: BETA_REQUEST_LABEL });
  } catch (error) {
    // 404 = already removed by a person or a concurrent run; it is gone either way.
    if (error.status !== 404) {
      throw callFailed(error, `label removal of "${BETA_REQUEST_LABEL}"`,
        `The label may still be on the PR and no beta build was started: remove it by hand first, then add "${BETA_REQUEST_LABEL}" again.`);
    }
  }
  const refuse = (notice) => {
    log(notice);
    return { status: 'refused', notice };
  };

  const isRelease = pr.state === 'open' && isReleasePr(pr.labels);
  if (!isRelease) return refuse(`PR #${pr.number} is not an open "${RELEASE_PR_LABEL}" release PR - no beta build`);
  if (!fromThisRepo(pr, { owner, repo })) {
    return refuse(`PR #${pr.number} does not come from ${owner}/${repo} - no beta build`);
  }

  let role;
  try {
    role = await checkMaintainer({ github, owner, repo, login: sender });
  } catch (error) {
    throw callFailed(error, `role lookup of ${sender}`, addAgain);
  }
  if (!role.allowed) return refuse(role.notice);

  try {
    await github.rest.actions.createWorkflowDispatch({
      owner, repo, workflow_id: 'beta-build.yml', ref, inputs: { pr_number: String(pr.number) },
      headers: { 'X-GitHub-Api-Version': GITHUB_API_VERSION },
    });
  } catch (error) {
    throw callFailed(error, 'dispatch of beta-build.yml', addAgain);
  }
  log(`Dispatched beta-build.yml for PR #${pr.number} (requested by ${sender})`);
  return { status: 'dispatched', prNumber: pr.number };
}

// The message of the alias commit for the whole set: the subject names the X.Y.Z the packages share,
// the body lists every alias in order (each package has its own BUILD, so no single BUILD is named).
// `builds` is what buildBeta returns ([{ package, version, build }]). The package name is whatever
// sfdx-project.json holds (it may carry an apostrophe), so it is only ever put into a string here.
function aliasCommitMessage(builds) {
  if (builds.length === 0 || new Set(builds.map((built) => built.version)).size !== 1) throw new Error('The alias commit message needs the builds of one version');
  const lines = builds.map((built) => `- ${built.package}@${built.version}.${built.build}`);
  return `chore: record beta build aliases of ${builds[0].version}\n\n${lines.join('\n')}`;
}

module.exports = { decideBuild, buildBeta, selectBetaPr, checkBetaPr, planBeta, pushAliasCommit, requestBetaBuild, canStartBeta, aliasCommitMessage };
