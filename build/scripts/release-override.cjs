// =============================================================================
// release-override.cjs - Sync the override box, label and preview of a release PR
// =============================================================================
// Orchestrator required by release-notes-override.yml. This file is only the sync loop. The parts live
// in release-box.cjs (box and authority), release-label.cjs (the override label), release-record.cjs (what a branch records, whether it is current),
// release-notes.cjs (notesFor: the generated and effective notes, with the package set header), release-preview.cjs
// (rendering and the sticky comment) and release-comments.cjs (shared comment helpers).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { BOX_STATE, ensureBox } = require('./release-box.cjs');
const { listLabelNames, syncOverrideLabel } = require('./release-label.cjs');
const { RELEASE_PR_LABEL, isReleasePr } = require('./release-pr.cjs');
const { notesFor, fenceFor, listTagNames } = require('./release-notes.cjs');
const { BETA_STATE, differingBuilds, readBetaBuildState } = require('./release-record.cjs');
const { findDrift, renderPreview, upsertPreview } = require('./release-preview.cjs');

// The step runner: a step that throws is recorded, never rethrown, so the steps
// stay independent. `work` returns { value, result }.
function createStepRunner(prNumber, log) {
  const failed = [];
  const results = {};
  return {
    failed,
    results,
    async run(name, work) {
      try {
        const { value, result } = await work();
        results[name] = result;
        return value;
      } catch (error) {
        failed.push(name);
        results[name] = `failed: ${error.message}`;
        log(`PR #${prNumber}: ${name} step failed: ${error.message}`);
        return undefined;
      }
    },
    skip(name, reason) {
      results[name] = `skipped (${reason})`;
    },
  };
}

function describeBox(box, created) {
  return `${box.state}${created ? ' (created)' : ''}${box.reason ? `, ${box.reason}` : ''}`;
}

// The run summary: one line per step and, when known, the full effective notes
// in a fence longer than any backtick run inside them (untrusted text).
function renderSummary(prNumber, results, effective, warnings = []) {
  const lines = [`### Release notes override - PR #${prNumber}`, '',
    ...Object.entries(results).map(([step, result]) => `- ${step}: ${result}`)];
  if (warnings.length > 0) {
    lines.push('', '#### Warnings', '', ...warnings.map((warning) => `- ${warning}`));
  }
  if (effective !== null) {
    const fence = fenceFor(effective);
    lines.push('', '#### Effective release notes (full text)', '', `${fence}markdown`, effective, fence);
  }
  return `${lines.join('\n')}\n`;
}

// Recompute everything for one release PR, idempotently: ensure the override
// box, mirror it in the label and refresh the preview. The steps are separate
// steps, so one failing never skips or undoes another; the caller ends the job
// red when `failed` is not empty. Override text is untrusted: it is never
// logged, only returned in `summary`, fenced, for the run summary.
// Collection warnings (what the notes could not read) keep the run green (
// warn, not fail) but are returned in `warnings` (one line each, for annotations),
// counted in the release step result and listed in the run summary.
// Returns { action: 'skipped' | 'synced', failed: [step], summary, warnings }.
async function syncRelease({ github, owner, repo, prNumber, log = console.log }) {
  const ctx = { github, owner, repo, prNumber };
  if (!isReleasePr(await listLabelNames(ctx))) {
    log(`PR #${prNumber} is not a release PR (no "${RELEASE_PR_LABEL}" label) - skipping`);
    return { action: 'skipped', failed: [], summary: '', warnings: [] };
  }

  const steps = createStepRunner(prNumber, log);
  const box = await steps.run('box', async () => {
    const { created, box: current } = await ensureBox(ctx);
    log(`PR #${prNumber}: override box ${describeBox(current, created)}`);
    return { value: current, result: describeBox(current, created) };
  });

  // What the release branch records is read once (release-record.cjs); the notes and
  // the preview build on it. The beta build state is shown by the required check
  // `Release readiness` only.
  const releaseBranch = await steps.run('record', async () => {
    const head = (await github.rest.pulls.get({ owner, repo, pull_number: prNumber })).data.head.ref;
    const record = await readBetaBuildState({ github, owner, repo, ref: head });
    return { value: { head, record }, result: `${record.version}, ${{ [BETA_STATE.NONE]: 'no beta build recorded', [BETA_STATE.CURRENT]: 'beta build recorded', [BETA_STATE.STALE]: 'beta build recorded but stale' }[record.state]}` };
  });

  // The release notes (install links, merged PRs, generated and effective notes) build
  // on the record and on the box read above. The preview depends on them.
  let release;
  if (releaseBranch) {
    release = await steps.run('release', async () => {
      const { head, record } = releaseBranch;
      const info = await notesFor({
        github, owner, repo, version: record.version, head, compareTo: head, log,
        builds: record.builds,
        tagNames: await listTagNames({ github, owner, repo }),
        box: box || null,
      });
      const warned = info.warnings.length > 0 ? `, ${info.warnings.length} warning${info.warnings.length === 1 ? '' : 's'}` : '';
      return { value: { ...info, version: record.version }, result: `${record.version}, ${info.builds.some((built) => built.installId) ? 'install links' : 'no install links'}${warned}` };
    });
  } else {
    steps.skip('release', 'record unavailable');
  }

  // Untrusted API text, flattened once by notesFor, for the preview, the summary and the annotations.
  // The packages share X.Y.Z, each keeps its own BUILD: a record whose numbers differ is shown, never blocked.
  const buildWarning = releaseBranch ? differingBuilds(releaseBranch.record.packages) : null;
  const warnings = [...(release ? release.warnings : []), ...(buildWarning ? [buildWarning] : [])];

  let effective = null;
  if (box) {
    const active = box.state === BOX_STATE.ACTIVE;
    await steps.run('label', async () => ({
      result: (await syncOverrideLabel({ ...ctx, active, log })).action,
    }));
    if (release) {
      await steps.run('preview', async () => {
        const drift = active ? findDrift(release.prs, box.body) : [];
        effective = release.effective.text;
        const body = renderPreview({ version: release.version, generated: release.generated, box, drift, builds: release.builds, warnings });
        return { result: (await upsertPreview({ ...ctx, body })).action };
      });
    } else {
      steps.skip('preview', 'release info unavailable');
    }
  } else {
    steps.skip('label', 'box unavailable');
    steps.skip('preview', 'box unavailable');
  }

  return { action: 'synced', failed: steps.failed, summary: renderSummary(prNumber, steps.results, effective, warnings), warnings };
}

module.exports = { syncRelease };
