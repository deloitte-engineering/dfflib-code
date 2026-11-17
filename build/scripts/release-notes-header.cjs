// =============================================================================
// release-notes-header.cjs - The header of the release notes: the package set and the upstream pins
// =============================================================================
// A pure render, no API calls and no I/O. renderHeader() leads the release notes with one table,
// `Package | Install links | Notes`, a row per package: the unlocked packages first, then the BYO
// packages (bring your own fflib), each group in the order given. The Notes cell of an unlocked
// package lists its Upstream pins ("Incl. A and B"); the Notes cell of a BYO package is one constant.
// The table is followed by the getting-started line. installLines() renders the same set as the
// bullet list of the release PR preview (no pins). Both read one package set,
// [{ package, kind, installId | null }] (the `builds` of release-record.cjs recordedBetaBuild; kind
// is a PACKAGE_KIND, never taken from a name; installId null while no beta build is recorded for
// it).
// Also owns installUrls, the one "install links pending" text and the getting-started URL.
// Used by release-notes.cjs (buildReleaseNotes) and release-preview.cjs (renderPreview).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { BETA_REQUEST_LABEL } = require('./release-label.cjs');
const { PACKAGE_KIND, standaloneFirst } = require('./release-package-set.cjs');

// The one text for a package without a recorded beta build.
const LINKS_PENDING = `install links pending (no beta build is recorded for this version; a maintainer adds the label \`${BETA_REQUEST_LABEL}\` to this PR to build one)`;

// The one place of the getting-started URL (unverified: open it after the first release that uses it).
const GETTING_STARTED_URL = 'https://github.com/deloitte-engineering/dfflib/how/get-started';

// The Notes cell of a BYO package: one constant, no org type.
const BYO_NOTES = 'Requires fflib installed';

// What a person is told about each kind of package in the preview bullets. The names of the packages
// are only labels.
const KIND_LABEL = Object.freeze({
  [PACKAGE_KIND.STANDALONE]: 'unlocked',
  [PACKAGE_KIND.BYO]: 'BYO, needs fflib installed',
});

// Install links for a 04t package version id.
function installUrls(installId) {
  return {
    sandboxUrl: `https://test.salesforce.com/packaging/installPackage.apexp?p0=${installId}`,
    prodUrl: `https://login.salesforce.com/packaging/installPackage.apexp?p0=${installId}`,
  };
}

// A package name is text from sfdx-project.json: one line, no markup, no table cell break, and
// a zero-width space after "@" so it neither links nor notifies a login.
function escapeCell(text) {
  return String(text)
    .replace(/\s+/g, ' ')
    .replace(/[\\`<>[\]&|]/g, (char) => `\\${char}`)
    .replace(/@/g, '@\u200b');
}

// The `Sandbox / Production` pair of one package, or null without a recorded build.
function linkPair(build) {
  if (!build.installId) return null;
  const { sandboxUrl, prodUrl } = installUrls(build.installId);
  return `[Sandbox](${sandboxUrl}) / [Production](${prodUrl})`;
}

// One upstream pin: the name with the end commit linked to the upstream repository. With the previous
// release tag's pin of the same upstream (`previousSha`) that differs, a compare link labelled with the
// previous tag; an unchanged pin and a pin without a previous release show the commit only. Upstream
// commit titles are never listed.
function pinText({ name, url, sha, previousSha }, previousTag) {
  const commit = `[${sha.slice(0, 7)}](${url}/commit/${sha})`;
  const compare = previousTag && previousSha && previousSha !== sha ? `, [compare with ${escapeCell(previousTag)}](${url}/compare/${previousSha}...${sha})` : '';
  return `${escapeCell(name)} (${commit}${compare})`;
}

// "A", "A and B", "A, B and C".
function joinList(items) {
  if (items.length <= 1) return items.join('');
  return `${items.slice(0, -1).join(', ')} and ${items[items.length - 1]}`;
}

// The Notes cell of a package: "Incl." and its pins for an unlocked package (empty without pins),
// the constant for a BYO package.
function notesCell(build, pins, previousTag) {
  if (build.kind === PACKAGE_KIND.BYO) return BYO_NOTES;
  if (pins.length === 0) return '';
  return `Incl. ${joinList(pins.map((each) => pinText(each, previousTag)))}`;
}

// The header under the title of the notes, ending with a newline.
//   builds       the package set (see above); may be in any order
//   pins         [{ name, url, sha, previousSha? }]: the Upstream pins at the release, each with the pin of
//                the same upstream at the previous release tag when that is known
//   previousTag  the previous release tag ('' for a first release)
// The table and the getting-started line are separated by a blank line so GitHub renders each on its
// own. A set of one package still gets the table, with one row.
function renderHeader({ builds, pins = [], previousTag = '' }) {
  if (builds.length === 0) return '';
  const rows = standaloneFirst(builds).map((build) => {
    const links = linkPair(build) || LINKS_PENDING;
    const notes = notesCell(build, pins, previousTag);
    return `| ${escapeCell(build.package)} | ${links} |${notes ? ` ${notes} |` : ' |'}`;
  });
  const table = ['| Package | Install links | Notes |', '| --- | --- | --- |', ...rows].join('\n');
  return `${table}\n\nCheck [Getting started guide](${GETTING_STARTED_URL}) for install and upgrade support.\n`;
}

// The install bullets of the release PR preview: one per package, unlocked first and in bold, each
// tagged with its kind; a package without a build gets the pending text. No pins.
function installLines(builds) {
  return standaloneFirst(builds).map((build) => {
    const links = linkPair(build) || LINKS_PENDING;
    const label = `${KIND_LABEL[build.kind]}: ${escapeCell(build.package)}`;
    return `- ${build.kind === PACKAGE_KIND.STANDALONE ? `**${label}**` : label}: ${links}`;
  }).join('\n');
}

module.exports = { LINKS_PENDING, GETTING_STARTED_URL, installUrls, renderHeader, installLines };
