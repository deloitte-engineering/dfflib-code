// =============================================================================
// pr-labels.cjs - The title and community labels of a PR
// =============================================================================
// The decisions behind pr-labels.yml's two github-script steps:
//   syncConventionalLabels  one type label from the PR title type, plus
//                           `breaking` from a title `!` or a `BREAKING CHANGE:` line
//   syncCommunityLabel      `community` for external contributors, never for bots
// The title types and the title parser are pr-title.cjs; the file labels are
// actions/labeler (the scope labels). Non-destructive: an invalid title or an unmapped
// type never strips a label that is already right.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { parseTitle } = require('./pr-title.cjs');

// title type -> type label; any other type has none.
const LABEL_BY_TYPE = {
  feat: 'enhancement',
  fix: 'bug',
  chore: 'chore',
  refactor: 'refactor',
  perf: 'performance',
};
const BREAKING_LABEL = 'breaking';
const COMMUNITY_LABEL = { name: 'community', color: '7057ff', description: 'Contribution from an external community member' };

function labelForType(type) {
  return LABEL_BY_TYPE[type] || '';
}

// Decide which conventional labels to add/remove for a PR type. A blank
// expectedLabel (invalid title or unmapped type) MUST leave labels untouched --
// otherwise a stale/racing title read would strip a correctly-applied label.
function reconcileConventionalLabels(type, currentLabels) {
  const expectedLabel = labelForType(type);
  const toAdd = [];
  const toRemove = [];
  if (!expectedLabel) {
    return { expectedLabel, toAdd, toRemove };
  }
  for (const label of Object.values(LABEL_BY_TYPE)) {
    if (label !== expectedLabel && currentLabels.includes(label)) {
      toRemove.push(label);
    }
  }
  if (!currentLabels.includes(expectedLabel)) {
    toAdd.push(expectedLabel);
  }
  return { expectedLabel, toAdd, toRemove };
}

// A breaking marker is `!` right before the title's colon, or a
// `BREAKING CHANGE:` line in the description.
function isBreakingChange({ title, body }) {
  return parseTitle(title).breaking || /^BREAKING CHANGE:/m.test(body || '');
}

function reconcileBreakingLabel(breaking, currentLabels) {
  const present = currentLabels.includes(BREAKING_LABEL);
  return {
    toAdd: breaking && !present ? [BREAKING_LABEL] : [],
    toRemove: !breaking && present ? [BREAKING_LABEL] : [],
  };
}

// Decide whether to apply the `community` label. Internal contributors are
// identified by explicit membership signals (repo collaborator or a confirmed
// org membership) rather than author_association, which under-reports members.
// Bots (the PR author, never the event actor) are neither collaborators nor org
// members, so they would otherwise read as external.
function shouldLabelCommunity({ isBot, isCollaborator, isOrgMember }) {
  if (isBot) return false;
  if (isCollaborator) return false;
  if (isOrgMember) return false;
  return true;
}

// Sync the conventional and breaking labels of a PR from a fresh read of its title and
// description (webhook payloads can be stale on rapid edits). A title that does not
// follow the format changes nothing: pr-template.cjs is the one blocking title check.
// Returns { valid, type, expectedLabel }.
async function syncConventionalLabels({ github, owner, repo, prNumber, log, warn }) {
  const { data: pr } = await github.rest.pulls.get({ owner, repo, pull_number: prNumber });
  const { type, valid } = parseTitle(pr.title);
  if (!valid) {
    log(`Title "${pr.title}" does not follow the format: labels untouched`);
    return { valid, type, expectedLabel: '' };
  }

  const currentLabels = (await github.paginate(github.rest.issues.listLabelsOnIssue, {
    owner, repo, issue_number: prNumber, per_page: 100,
  })).map((label) => label.name);

  const breaking = isBreakingChange({ title: pr.title, body: pr.body });
  const breakingDiff = reconcileBreakingLabel(breaking, currentLabels);
  log(`breaking marker: ${breaking}`);
  // A failed breaking-label write must not block the conventional label below.
  try {
    for (const name of breakingDiff.toRemove) {
      await github.rest.issues.removeLabel({ owner, repo, issue_number: prNumber, name });
    }
    if (breakingDiff.toAdd.length > 0) {
      await github.rest.issues.addLabels({ owner, repo, issue_number: prNumber, labels: breakingDiff.toAdd });
    }
  } catch (error) {
    warn(`Could not sync the breaking label: ${error.message}`);
  }

  const { expectedLabel, toAdd, toRemove } = reconcileConventionalLabels(type, currentLabels);
  if (!expectedLabel) {
    log(`type "${type}" has no conventional label`);
    return { valid, type, expectedLabel };
  }
  log(`type "${type}" -> ${expectedLabel}`);

  for (const name of toRemove) {
    try {
      await github.rest.issues.removeLabel({ owner, repo, issue_number: prNumber, name });
    } catch (error) { /* a concurrent run removed it first */ }
  }
  if (toAdd.length > 0) {
    await github.rest.issues.addLabels({ owner, repo, issue_number: prNumber, labels: toAdd });
    log(`Applied ${expectedLabel}`);
  }
  return { valid, type, expectedLabel };
}

// A 204 answer means yes; any error (404, or 302 for a hidden member) means no.
async function answers204(call) {
  try {
    await call();
    return true;
  } catch (error) {
    return false;
  }
}

// Label a PR from an external contributor `community`. `pr` is the payload PR
// ({ number, user: { login, type } }). Returns { external }.
async function syncCommunityLabel({ github, owner, repo, pr, log }) {
  const author = pr.user.login;
  const isBot = pr.user.type === 'Bot';
  const isCollaborator = await answers204(() => github.rest.repos.checkCollaborator({ owner, repo, username: author }));
  const isOrgMember = await answers204(() => github.rest.orgs.checkMembershipForUser({ org: owner, username: author }));
  const external = shouldLabelCommunity({ isBot, isCollaborator, isOrgMember });
  log(`author=${author} isBot=${isBot} isCollaborator=${isCollaborator} isOrgMember=${isOrgMember} => ${external ? 'EXTERNAL' : 'INTERNAL'}`);
  if (!external) return { external };

  try {
    await github.rest.issues.getLabel({ owner, repo, name: COMMUNITY_LABEL.name });
  } catch (error) {
    if (error.status !== 404) throw error;
    try {
      await github.rest.issues.createLabel({ owner, repo, ...COMMUNITY_LABEL });
    } catch (createError) {
      // 422 = a concurrent run created it first; the label exists either way.
      if (createError.status !== 422) throw createError;
    }
  }
  await github.rest.issues.addLabels({ owner, repo, issue_number: pr.number, labels: [COMMUNITY_LABEL.name] });
  log(`Added the community label to PR #${pr.number}`);
  return { external };
}

module.exports = {
  labelForType, reconcileConventionalLabels, isBreakingChange, reconcileBreakingLabel, shouldLabelCommunity,
  syncConventionalLabels, syncCommunityLabel,
};
