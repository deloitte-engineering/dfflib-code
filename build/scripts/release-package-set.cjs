// =============================================================================
// release-package-set.cjs - The package entries of sfdx-project.json
// =============================================================================
// The one module that reads the package entries of sfdx-project.json. It takes the
// text of the file and returns the entries in file order, each with its name, path,
// version number, base version (X.Y.Z) and whether it is the default entry: the entry
// marked `default: true`, otherwise the first. A project without package entries gives
// one clear error here instead of a TypeError at each caller. Pure: no network, no git.
// Used by release-record.cjs (the recorded beta build, its state and the content tag
// guard), release-beta.cjs (the plan) and release-publish.cjs (the content tag guard).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

// X.Y.Z of a versionNumber (X.Y.Z.NEXT or X.Y.Z.BUILD).
function baseVersion(versionNumber) {
  return versionNumber.split('.').slice(0, 3).join('.');
}

// The two package kinds. The default entry is the monolith package; every other entry is the
// BYO package (bring your own fflib; org-dependent, so it has no coverage figure). The kind never
// comes from a name; it is recomputed from the project file on every run and never persisted.
const PACKAGE_KIND = Object.freeze({ MONOLITH: 'monolith', BYO: 'byo' });

// The entries of `projectText` (sfdx-project.json) as
// [{ name, path, versionNumber, baseVersion, isDefault, kind }] in file order; exactly one is the
// default. Throws when the file lists no package entries.
function packageSet(projectText) {
  const { packageDirectories } = JSON.parse(projectText);
  if (!Array.isArray(packageDirectories) || packageDirectories.length === 0) {
    throw new Error('sfdx-project.json lists no package entries');
  }
  const marked = packageDirectories.findIndex((dir) => dir.default === true);
  const defaultIndex = marked === -1 ? 0 : marked;
  return packageDirectories.map((dir, index) => ({
    name: dir.package,
    path: dir.path,
    versionNumber: dir.versionNumber,
    baseVersion: dir.versionNumber ? baseVersion(dir.versionNumber) : null,
    isDefault: index === defaultIndex,
    kind: index === defaultIndex ? PACKAGE_KIND.MONOLITH : PACKAGE_KIND.BYO,
  }));
}

// `list` (anything with a `kind`) with the monolith first, the others after it in the order given.
const monolithFirst = (list) => [
  ...list.filter((each) => each.kind === PACKAGE_KIND.MONOLITH),
  ...list.filter((each) => each.kind !== PACKAGE_KIND.MONOLITH),
];

module.exports = { packageSet, baseVersion, PACKAGE_KIND, monolithFirst };
