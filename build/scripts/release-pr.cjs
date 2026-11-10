// =============================================================================
// release-pr.cjs - What a release PR is, and who may act on it
// =============================================================================
// The one module that decides it.
//   RELEASE_PR_LABEL, isReleasePr   identity: a release PR is an open PR with the label
//                                   release-please puts on it
//   fromThisRepo                    the fork rule: the PR head must live in this repository
//   selectReleasePr                 pure: the release PR among PRs, or the one named by an input
//   listOpenReleasePrs              GitHub: the open release PRs, every page
//   checkMaintainer                 GitHub: the Maintainer role rule (maintain or admin)
// No workflow script paginates or filters by the label itself, and no other module decides
// who a Maintainer is. Used by release-beta.cjs, release-box.cjs, release-readiness.cjs,
// release-override.cjs, release-publish.cjs, beta-build.yml and release-notes-override.yml.
// Whether a branch records a current beta build is not decided here (release-record.cjs).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const RELEASE_PR_LABEL = 'autorelease: pending';

// The release PR identity, once: a PR is the release PR when it carries the label
// release-please puts on it. labels are names or label objects as the API returns them.
const isReleasePr = (labels) => labels.some((label) => (typeof label === 'string' ? label : label.name) === RELEASE_PR_LABEL);

// The fork rule, once: the release branch is data we build and push to, so the PR
// head must live in this repository. `pr` comes from the pulls API (issue objects
// have no head).
function fromThisRepo(pr, { owner, repo }) {
  return Boolean(pr.head && pr.head.repo && pr.head.repo.full_name === `${owner}/${repo}`);
}

// The release PR among `prs` (PRs as the pulls API or issue objects with labels), or
// the one named by the optional manual `prNumber` (which must be such a PR too).
// Returns { pr }, or { notice } when there is none or the choice is ambiguous.
function selectReleasePr(prs, prNumber) {
  const pendingPrs = prs.filter((pr) => isReleasePr(pr.labels));
  const wanted = prNumber === undefined || prNumber === null || String(prNumber).trim() === '' ? null : Number(prNumber);
  if (wanted !== null) {
    const pr = pendingPrs.find((candidate) => candidate.number === wanted);
    return pr ? { pr } : { notice: `PR #${wanted} is not an open "${RELEASE_PR_LABEL}" release PR - nothing to build` };
  }
  if (pendingPrs.length === 1) return { pr: pendingPrs[0] };
  if (pendingPrs.length === 0) return { notice: `No open "${RELEASE_PR_LABEL}" release PR - nothing to build` };
  return { notice: `${pendingPrs.length} open "${RELEASE_PR_LABEL}" PRs (${pendingPrs.map((pr) => `#${pr.number}`).join(', ')}) - pass pr_number to pick one` };
}

// The open release PRs as issue objects (they have labels, no head), every page.
// Issues that are not PRs are dropped.
async function listOpenReleasePrs({ github, owner, repo }) {
  const labelled = await github.paginate(github.rest.issues.listForRepo, {
    owner, repo, state: 'open', labels: RELEASE_PR_LABEL, per_page: 100,
  });
  return labelled.filter((issue) => issue.pull_request);
}

// The Maintainer role rule, once: the maintain and admin
// repository roles. getCollaboratorPermissionLevel reports `role_name` (admin, maintain,
// write, triage, read, or a custom role name) and the legacy `permission`, which folds
// maintain into write, so without `role_name` only the legacy `admin` is certain.
const MAINTAINER_ROLES = ['maintain', 'admin'];

// Does `login` hold a Maintainer role? Returns { allowed, notice? }. A 404 means the
// login is not a collaborator: a refusal, not an error. Any other failed lookup throws:
// it must not turn into a refusal. The [bot] allowance of beta-build.yml is not part of
// this rule (canStartBeta in release-beta.cjs).
async function checkMaintainer({ github, owner, repo, login }) {
  let level;
  try {
    level = (await github.rest.repos.getCollaboratorPermissionLevel({ owner, repo, username: login })).data;
  } catch (error) {
    if (error.status !== 404) throw error;
    return { allowed: false, notice: `${login} is not a collaborator of ${owner}/${repo}; ${MAINTAINER_ROLES.join(' or ')} is needed` };
  }
  const allowed = level.role_name ? MAINTAINER_ROLES.includes(level.role_name) : level.permission === 'admin';
  if (allowed) return { allowed: true };
  return { allowed: false, notice: `${login} has the "${level.role_name || level.permission}" role; ${MAINTAINER_ROLES.join(' or ')} is needed` };
}

module.exports = { RELEASE_PR_LABEL, isReleasePr, fromThisRepo, selectReleasePr, listOpenReleasePrs, checkMaintainer };
