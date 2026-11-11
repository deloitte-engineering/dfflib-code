// =============================================================================
// release-readiness.cjs - Is a PR ready to merge as far as the release is concerned?
// =============================================================================
// The logic of the required check `Release readiness` (release-readiness.yml).
// A release PR is ready only when its head records a current beta build of every package
// of the set and the package entries of sfdx-project.json carry one X.Y.Z; every other PR is
// ready. The release PR identity comes from release-pr.cjs (isReleasePr), the
// state from release-record.cjs (readBetaBuildState): no copy of either, no Dev Hub
// read, and never the conclusion of a beta-build.yml run (R7).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { BETA_REQUEST_LABEL } = require('./release-label.cjs');
const { isReleasePr } = require('./release-pr.cjs');
const { BETA_STATE, STALE_REASON, differingBuilds, readBetaBuildState } = require('./release-record.cjs');

const ASK_FOR_BUILD = `Add the label \`${BETA_REQUEST_LABEL}\` to this PR to request a new beta build.`;
// Without an alias commit no new build of the same content helps: the reuse records the same alias, so
// nothing changes until release-please rebuilds the branch, which drops the alias.
const CLEARS_ON_REBUILD = 'A new beta build of the same content does not change that; this clears when release-please next rebuilds this branch, which drops the alias, and a new beta build is requested.';

// Why a recorded beta build is stale, as the reader needs it, from the reason the record gives
// ({ code, package }): the message is built from the reason, never inferred from other fields.
function staleReason({ code, package: name }) {
  const messages = {
    [STALE_REASON.PACKAGE_MISSING]: `${name} has no recorded beta build. ${ASK_FOR_BUILD}`,
    [STALE_REASON.ALIAS_COMMIT_NOT_FOUND]: `the commit that recorded the ${name} build cannot be found, so it cannot be shown to match this branch. ${CLEARS_ON_REBUILD}`,
    [STALE_REASON.ALIAS_PARENT_NOT_FOUND]: `the commit the ${name} build started from cannot be found, so it cannot be shown to match this branch. ${CLEARS_ON_REBUILD}`,
    [STALE_REASON.CONTENT_UNREADABLE]: `the content of the ${name} build cannot be read at the commit the build started from or at this commit, so it cannot be shown to match this branch.`,
    [STALE_REASON.CONTENT_CHANGED]: `the content (the content roots) changed after the ${name} build was built. ${ASK_FOR_BUILD}`,
  };
  return messages[code];
}

// The distinct X.Y.Z base versions of the package entries, as "package X.Y.Z" in file order, when
// they differ; else null. release-please bumps only the default entry, and an extra-files jsonpath that
// matches nothing leaves another entry behind without any error, so this check is the only place that notices.
function versionMismatch(record) {
  const known = record.versions.filter((entry) => entry.baseVersion);
  if (new Set(known.map((entry) => entry.baseVersion)).size <= 1) return null;
  return known.map((entry) => `${entry.package} ${entry.baseVersion}`).join(', ');
}

// PR `prNumber` at `headSha`, the commit the check reports on. The labels are read fresh
// (the payload can be stale); the state is read at headSha, never at the branch, which
// may have moved on to other content. Returns { ready, state, message, warning }; state is null
// for a PR that is not the release PR. `warning` is differingBuilds of the recorded builds (the packages
// share X.Y.Z, each keeps its own BUILD): a text the message repeats, or null. It never changes `ready`.
async function checkReleaseReadiness({ github, owner, repo, prNumber, headSha }) {
  const pr = (await github.rest.pulls.get({ owner, repo, pull_number: prNumber })).data;
  if (!isReleasePr(pr.labels)) return { ready: true, state: null, message: `PR #${prNumber} is not a release PR - nothing to check.`, warning: null };
  const record = await readBetaBuildState({ github, owner, repo, ref: headSha });
  const mismatch = versionMismatch(record);
  if (mismatch) {
    return {
      ready: false,
      state: record.state,
      warning: null,
      message: `Release PR #${prNumber}: the package entries of sfdx-project.json carry different X.Y.Z versions (${mismatch}). release-please bumps only the default entry; the other entries are bumped through \`extra-files\` in release-please-config.json, and a jsonpath that matches nothing leaves an entry behind without an error.`,
    };
  }
  const warning = differingBuilds(record.packages);
  const buildIds = record.packages.map((built) => `${built.package} build ${built.build}, ${built.installId}`).join('; ');
  const messages = {
    [BETA_STATE.NONE]: `Release PR #${prNumber} records no beta build of ${record.version}. Add the label \`${BETA_REQUEST_LABEL}\` to request a beta build.`,
    [BETA_STATE.STALE]: `The beta build of ${record.version} recorded on release PR #${prNumber} (${buildIds}) is stale: ${record.reason ? staleReason(record.reason) : ''}`,
    [BETA_STATE.CURRENT]: `Release PR #${prNumber} records a current beta build of ${record.version} (${buildIds}).`,
  };
  return { ready: record.state === BETA_STATE.CURRENT, state: record.state, message: warning ? `${messages[record.state]} ${warning}.` : messages[record.state], warning };
}

module.exports = { checkReleaseReadiness };
