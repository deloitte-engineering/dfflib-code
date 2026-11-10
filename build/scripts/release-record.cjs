// =============================================================================
// release-record.cjs - Does a ref record a beta build of its version?
// =============================================================================
// The one module that knows how sfdx-project.json records a beta build: one alias
// `<package>@X.Y.Z.<build>` (the 04t id of the beta build) for each package of the package
// set. It reads the record (recordedBetaBuild), says whether it is none, current or stale
// (betaBuildState, readBetaBuildState) and writes it (applyBetaAlias), so the alias
// format lives in one place. The content tag it compares comes from release-content-tag.cjs.
// No dependency on the release notes or on GitHub beyond the injected client. Used by
// release-beta.cjs (plan), beta-build.yml (alias commit, content tag), release-override.cjs
// (the install links via release-notes.cjs), release-readiness.cjs (the Release readiness
// check) and release-publish.cjs (the state and the content tag guard).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { packageSet, baseVersion } = require('./release-package-set.cjs');
const { CONTENT_INPUTS, contentTag } = require('./release-content-tag.cjs');

// The build number when `text` is `<prefix><digits>` (an alias key or a package
// version row, prefix `<package>@X.Y.Z.` or `X.Y.Z.`), else null. A non-numeric
// suffix such as LATEST is never a build.
function buildNumber(text, prefix) {
  if (!text.startsWith(prefix)) return null;
  const rest = text.slice(prefix.length);
  return /^\d+$/.test(rest) ? Number(rest) : null;
}

// The alias key of a beta build, `<package>@X.Y.Z.<build>`: the one place the shape
// is defined. aliasPrefix is the part before the build, for reading keys back
// through buildNumber.
function aliasPrefix(packageName, version) {
  return `${packageName}@${version}.`;
}
function aliasKey(packageName, version, build) {
  return `${aliasPrefix(packageName, version)}${build}`;
}

// The highest-build alias of `<package>@<version>.BUILD` of each package in `packageNames`, as
// [{ package, build, id }] in the order given; a package without one is left out.
function latestBuildAlias(aliases, packageNames, version) {
  return packageNames.flatMap((packageName) => {
    const prefix = aliasPrefix(packageName, version);
    const builds = Object.entries(aliases || {})
      .map(([key, id]) => ({ package: packageName, build: buildNumber(key, prefix), id }))
      .filter((entry) => entry.build !== null)
      .sort((a, b) => b.build - a.build);
    return builds.length > 0 ? [builds[0]] : [];
  });
}

// What `projectText` (sfdx-project.json) records for the version it is on (the default
// package's versionNumber X.Y.Z.NEXT): { recorded, version, packages, missing, versions }.
//   packages  [{ package, version, build, installId, kind }] (kind: PACKAGE_KIND), one per package of the set that has an alias,
//             each read at its own X.Y.Z (the highest build); empty while recorded is false
//   builds    [{ package, kind, installId | null }] for every package of the set in file order (installId null
//             without an alias): the package set the release notes header renders
//   missing   the names of the packages without an alias (a partial record)
//   versions  [{ package, baseVersion }] of every package, for the same-X.Y.Z readiness check
//   recorded  at least one package has an alias
// release-please drops the aliases whenever it rebuilds the branch, so recorded false means a beta
// build is still to be recorded. Whether the record is current is betaBuildState. The packages share
// X.Y.Z and each carries its own BUILD (differingBuilds says when they differ); the reader returns
// each package with the build of its own alias.
function recordedBetaBuild(projectText) {
  const entries = packageSet(projectText);
  const aliases = JSON.parse(projectText).packageAliases;
  const found = entries.map((entry) => ({ entry, alias: latestBuildAlias(aliases, [entry.name], entry.baseVersion)[0] }));
  const packages = found
    .filter(({ alias }) => alias)
    .map(({ entry, alias }) => ({ package: alias.package, version: entry.baseVersion, build: alias.build, installId: alias.id, kind: entry.kind }));
  return {
    recorded: packages.length > 0,
    version: entries.find((entry) => entry.isDefault).baseVersion,
    packages,
    builds: found.map(({ entry, alias }) => ({ package: entry.name, kind: entry.kind, installId: alias ? alias.id : null })),
    missing: found.filter(({ alias }) => !alias).map(({ entry }) => entry.name),
    versions: entries.map((entry) => ({ package: entry.name, baseVersion: entry.baseVersion })),
  };
}

// The three states of a recorded beta build.
const BETA_STATE = Object.freeze({ NONE: 'none', CURRENT: 'current', STALE: 'stale' });

// Why a record is stale, in `reason.code` (with `reason.package`, the package it concerns).
const STALE_REASON = Object.freeze({
  PACKAGE_MISSING: 'package-missing',
  ALIAS_COMMIT_NOT_FOUND: 'alias-commit-not-found',
  ALIAS_PARENT_NOT_FOUND: 'alias-parent-not-found',
  CONTENT_UNREADABLE: 'content-unreadable',
  CONTENT_CHANGED: 'content-changed',
});

// Is the beta build that `projectText` (sfdx-project.json at `ref`) records current?
// Returns { state, reason, recorded, version, packages, missing, versions, aliasCommit }:
//   none     no alias for the version (recorded false).
//   current  every package of the set has an alias and the content tag at the parent of the alias
//            commit (the commit the build started from) equals the content tag at `ref`.
//   stale    anything else, including every case where git cannot answer (alias commit or its parent
//            or the content not found): fail safe, never current. `reason` says which, naming the package.
// `recorded` is the derived boolean (state is not none). aliasCommit is the commit that recorded the
// first package's alias (null for none, for a missing package and when it was not found). `reason` is null
// unless stale.
// `reads` is injected, all async: findAliasCommit(ref, aliasKey) -> sha or null,
// parentOf(sha) -> sha or null, objectAt(sha, path) -> tree or blob id or null. No Dev Hub, no secrets.
async function betaBuildState({ projectText, ref, reads }) {
  const record = recordedBetaBuild(projectText);
  if (!record.recorded) return { state: BETA_STATE.NONE, ...record, reason: null, aliasCommit: null };
  let aliasCommit = null;
  const stale = (code, packageName) => ({ state: BETA_STATE.STALE, ...record, reason: { code, package: packageName }, aliasCommit });
  if (record.missing.length > 0) return stale(STALE_REASON.PACKAGE_MISSING, record.missing[0]);
  let now;
  for (const built of record.packages) {
    const found = await reads.findAliasCommit(ref, aliasKey(built.package, built.version, built.build));
    if (!found) return stale(STALE_REASON.ALIAS_COMMIT_NOT_FOUND, built.package);
    aliasCommit = aliasCommit || found;
    const builtFrom = await reads.parentOf(found);
    if (!builtFrom) return stale(STALE_REASON.ALIAS_PARENT_NOT_FOUND, built.package);
    const tagThen = await contentTag(reads, builtFrom);
    now = now === undefined ? await contentTag(reads, ref) : now;
    if (!tagThen || !now) return stale(STALE_REASON.CONTENT_UNREADABLE, built.package);
    if (tagThen !== now) return stale(STALE_REASON.CONTENT_CHANGED, built.package);
  }
  return { state: BETA_STATE.CURRENT, ...record, reason: null, aliasCommit };
}

const PROJECT_FILE = 'sfdx-project.json';

// The text of sfdx-project.json at `ref` (a branch, tag or SHA). One read.
async function readProjectText({ github, owner, repo, ref }) {
  const { data } = await github.rest.repos.getContent({ owner, repo, path: PROJECT_FILE, ref });
  return Buffer.from(data.content, data.encoding || 'base64').toString('utf8');
}

// The git reads of betaBuildState over the GitHub API, so a workflow needs no checkout.
const COMMITS_PER_PAGE = 100;
const MAX_COMMIT_PAGES = 3;

function githubReads({ github, owner, repo }) {
  const firstParents = new Map();
  const rootTrees = new Map();
  const trees = new Map();
  const commitOf = async (ref) => (await github.rest.repos.getCommit({ owner, repo, ref })).data;
  // The entries of a tree, read once per tree id.
  const entriesOf = async (treeSha) => {
    if (!trees.has(treeSha)) trees.set(treeSha, (await github.rest.git.getTree({ owner, repo, tree_sha: treeSha })).data.tree);
    return trees.get(treeSha);
  };
  // Does sfdx-project.json at `sha` hold the alias `key`? A commit without the file does not.
  const holdsAt = async (sha, key) => {
    let text;
    try {
      text = await readProjectText({ github, owner, repo, ref: sha });
    } catch (error) {
      if (error.status === 404) return false;
      throw error;
    }
    return Object.hasOwn(JSON.parse(text).packageAliases || {}, key);
  };
  return {
    // The commit that recorded the alias: the newest commit that changed sfdx-project.json,
    // holds the alias and whose first parent does not. Commits from main never hold it, and a
    // merge that keeps it has a first parent that holds it, so neither is taken, whatever order
    // the list puts them in. Not found in the newest 300 such commits: null (stale), not a guess.
    async findAliasCommit(ref, key) {
      for (let page = 1; page <= MAX_COMMIT_PAGES; page += 1) {
        const { data: commits } = await github.rest.repos.listCommits({ owner, repo, sha: ref, path: PROJECT_FILE, per_page: COMMITS_PER_PAGE, page });
        for (const commit of commits) {
          const firstParent = commit.parents.length > 0 ? commit.parents[0].sha : null;
          firstParents.set(commit.sha, firstParent);
          if (!(await holdsAt(commit.sha, key))) continue;
          if (!firstParent || !(await holdsAt(firstParent, key))) return commit.sha;
        }
        if (commits.length < COMMITS_PER_PAGE) return null;
      }
      return null;
    },
    // The first parent: the commit the alias commit was made on top of (the commit the
    // build started from). Known from the commit list when findAliasCommit found it.
    async parentOf(sha) {
      if (firstParents.has(sha)) return firstParents.get(sha);
      const { parents } = await commitOf(sha);
      return parents.length > 0 ? parents[0].sha : null;
    },
    // The id (tree or blob) of `path` at a commit or ref, or null when it is not there. A path walks
    // the trees from the root; each tree is read once, so the content inputs cost a few reads.
    async objectAt(ref, path) {
      if (!rootTrees.has(ref)) rootTrees.set(ref, (await commitOf(ref)).commit.tree.sha);
      let id = rootTrees.get(ref);
      const segments = path.split('/').filter(Boolean);
      for (const [index, segment] of segments.entries()) {
        const entry = (await entriesOf(id)).find((item) => item.path === segment);
        if (!entry || (index < segments.length - 1 && entry.type !== 'tree')) return null;
        id = entry.sha;
      }
      return id;
    },
  };
}

// betaBuildState for sfdx-project.json at `ref`, read through the GitHub API.
async function readBetaBuildState({ github, owner, repo, ref }) {
  return betaBuildState({ projectText: await readProjectText({ github, owner, repo, ref }), ref, reads: githubReads({ github, owner, repo }) });
}

// The content tag guard of publish: may the recorded beta builds be promoted for a
// merge? `projectText` is sfdx-project.json that records them, `contentTag` the content tag at
// the merge commit (null when force-app is absent), `rows` the Dev Hub rows of the recorded 04t
// ids (each is found by its id, in any order). Passes only when every package of the set is
// recorded, each 04t is the recorded version and each was built from exactly that content, so a
// merge that also brought content changes is never released as the old build. A merge that
// changed only files outside the content inputs passes. Returns null when it passes, else the
// refusal.
function contentTagGuard({ projectText, contentTag: tag, rows }) {
  const record = recordedBetaBuild(projectText);
  if (!record.recorded) return `sfdx-project.json records no beta build of ${record.version}`;
  if (record.missing.length > 0) return `sfdx-project.json records no beta build of ${record.version} for ${record.missing.join(', ')}`;
  if (!tag) return `The merge commit has no ${CONTENT_INPUTS[0]} directory`;
  for (const built of record.packages) {
    const row = rows.find((each) => each.id === built.installId);
    if (!row) return `No Dev Hub version was read for ${built.package} (${built.installId})`;
    const recorded = `${built.version}.${built.build}`;
    if (row.version !== recorded) return `Beta build ${built.installId} of ${built.package} is version ${row.version}, but sfdx-project.json records ${recorded}`;
    if (row.tag !== tag) {
      return `The content roots at the merge commit (content tag ${tag}) are not the content beta build ${built.installId} of ${built.package} was built from (content tag ${row.tag || 'none'})`;
    }
  }
  return null;
}

// sfdx-project.json text with the alias `<package>@<version>.<build>` set to the
// 04t id of the beta build. Earlier numeric builds of the same version are
// replaced; other versions, packages and non-numeric keys are kept. Idempotent.
function applyBetaAlias(projectText, { packageName, version, build, id }) {
  const project = JSON.parse(projectText);
  const prefix = aliasPrefix(packageName, version);
  const aliases = {};
  for (const [key, value] of Object.entries(project.packageAliases || {})) {
    if (buildNumber(key, prefix) === null) aliases[key] = value;
  }
  aliases[aliasKey(packageName, version, build)] = id;
  project.packageAliases = aliases;
  return `${JSON.stringify(project, null, 2)}\n`;
}

// The packages of a release share X.Y.Z; each keeps the BUILD number its own Dev Hub package gave it, so the
// numbers can differ. The warning text when the `builds` (anything with { package, build }) do not all carry
// the same BUILD number, else null. It never blocks anything; the build step, the readiness check and the
// release PR preview show it so a person sees that the numbers differ.
function differingBuilds(builds) {
  if (new Set(builds.map((built) => built.build)).size <= 1) return null;
  const versions = new Set(builds.map((built) => built.version));
  const shared = versions.size === 1 && builds[0].version ? `version ${builds[0].version}` : 'the version X.Y.Z';
  return `The packages share ${shared} but their BUILD numbers differ (${builds.map((built) => `${built.package} ${built.build}`).join(', ')}); each package keeps its own`;
}

// sfdx-project.json text with the alias of every build in `builds` ([{ package, version, build, installId }],
// what buildBeta returns) recorded through applyBetaAlias. Each package gets its own alias with its own
// BUILD number; the numbers may differ (differingBuilds says so).
function applyBetaAliases(projectText, builds) {
  if (!Array.isArray(builds) || builds.length === 0) throw new Error('No beta build to record');
  return builds.reduce((text, built) => applyBetaAlias(text, { packageName: built.package, version: built.version, build: built.build, id: built.installId }), projectText);
}

module.exports = { BETA_STATE, STALE_REASON, baseVersion, buildNumber, aliasPrefix, aliasKey, latestBuildAlias, recordedBetaBuild, betaBuildState, readBetaBuildState, readProjectText, githubReads, contentTagGuard, differingBuilds, applyBetaAlias, applyBetaAliases };
