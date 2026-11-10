// =============================================================================
// release-label.cjs - The automation-managed override label of a release PR
// =============================================================================
// One automation-managed label, a mirror of a state and never a source of truth
// (nothing reads it as one), plus the literals that request a beta build and mark a
// published release (the release PR identity is release-pr.cjs):
//   `release-notes: override`  the override box holds a valid, non-empty override.
// `autorelease: tagged` is release-please's label of a published release PR; publish
// (release-publish.cjs) swaps `autorelease: pending` for it.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const OVERRIDE_LABEL = 'release-notes: override';
const RELEASE_TAGGED_LABEL = 'autorelease: tagged';
const BETA_REQUEST_LABEL = 'release: build-beta';

// How each managed label is created and how its state reads in the log.
const MANAGED_LABELS = {
  [OVERRIDE_LABEL]: {
    color: 'fbca04',
    description: 'Automation-managed: a maintainer override replaces the generated release notes',
    on: 'Override active',
    off: 'No active override',
  },
};

async function listLabelNames({ github, owner, repo, prNumber }) {
  return (await github.paginate(github.rest.issues.listLabelsOnIssue, {
    owner, repo, issue_number: prNumber, per_page: 100,
  })).map((label) => label.name);
}

// Create the repository label when it does not exist yet.
async function ensureLabelExists({ github, owner, repo, name }) {
  try {
    await github.rest.issues.getLabel({ owner, repo, name });
  } catch (error) {
    if (error.status !== 404) throw error;
    try {
      await github.rest.issues.createLabel({
        owner, repo, name, color: MANAGED_LABELS[name].color, description: MANAGED_LABELS[name].description,
      });
    } catch (createError) {
      // 422 = a concurrent run created it first; the label exists either way.
      if (createError.status !== 422) throw createError;
    }
  }
}

// Keep the managed label `name` equal to `active`.
// Returns { action: 'added' | 'removed' | 'unchanged' }.
async function syncManagedLabel({ github, owner, repo, prNumber, name, active, log }) {
  const meta = MANAGED_LABELS[name];
  const present = (await listLabelNames({ github, owner, repo, prNumber })).includes(name);

  if (active && !present) {
    await ensureLabelExists({ github, owner, repo, name });
    await github.rest.issues.addLabels({ owner, repo, issue_number: prNumber, labels: [name] });
    log(`${meta.on} - added "${name}"`);
    return { action: 'added' };
  }
  if (!active && present) {
    try {
      await github.rest.issues.removeLabel({ owner, repo, issue_number: prNumber, name });
    } catch (error) {
      // 404 = a concurrent run removed it first; the label is gone either way.
      if (error.status !== 404) throw error;
      log(`"${name}" was already removed`);
      return { action: 'unchanged' };
    }
    log(`${meta.off} - removed "${name}"`);
    return { action: 'removed' };
  }
  log(`Label "${name}" already in step (${active ? meta.on : meta.off})`);
  return { action: 'unchanged' };
}

const syncOverrideLabel = ({ log = console.log, ...rest }) => syncManagedLabel({ ...rest, name: OVERRIDE_LABEL, log });

module.exports = { OVERRIDE_LABEL, RELEASE_TAGGED_LABEL, BETA_REQUEST_LABEL, listLabelNames, syncOverrideLabel };