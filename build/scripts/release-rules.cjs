// =============================================================================
// release-rules.cjs - The rules preview and publish both need, once
// =============================================================================
// Pure functions, no GitHub and no Dev Hub:
//   effectiveNotes      the release notes to publish: an active override, else the generated notes
//   previousReleaseTag  the tag a release's changelog starts from
//   isPrerelease        the one prerelease rule
//   makeLatest          whether a tag takes the GitHub "Latest" badge
//   buildCheckFailures  rule R4: why a package version may not be promoted or reused
// Install links stay in release-notes.cjs (installUrls).
// Used by release-notes.cjs (notesFor), release-preview.cjs, release-override.cjs and
// release-publish.cjs, and by the beta build plan later.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { BOX_STATE } = require('./release-box.cjs');
const { PACKAGE_KIND } = require('./release-package-set.cjs');

// The notes a release publishes. `box` is the override box as readBox() reports it,
// `generated` is { notes, warnings } (the generated notes and what collecting the PRs
// could not read). Only an active override replaces the generated notes: an invalid box
// is never published. Returns { text, source: 'override' | 'generated', warnings };
// the warnings are a copy and are never dropped.
function effectiveNotes({ box, generated }) {
  const warnings = [...generated.warnings];
  if (box.state === BOX_STATE.ACTIVE) return { text: box.body, source: 'override', warnings };
  return { text: generated.notes, source: 'generated', warnings };
}

// The one prerelease rule: a tag (or version) that contains a "-".
const isPrerelease = (tag) => String(tag).includes('-');

// A final release tag as { x, y, z, build }: vX.Y.Z, or vX.Y.Z.BUILD for the releases
// before 1.2.0. A tag with a "-" or any other shape is not one (null). build is -1 for
// the three-part form.
function parseReleaseTag(tag) {
  const match = /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:\.(0|[1-9]\d*))?$/.exec(String(tag));
  if (!match) return null;
  return { x: Number(match[1]), y: Number(match[2]), z: Number(match[3]), build: match[4] === undefined ? -1 : Number(match[4]) };
}

// Order by X.Y.Z only. The BUILD segment is not part of a release's identity: the Dev Hub
// promotes one build per X.Y.Z (UNVERIFIED against the Salesforce docs, which could not be
// read), and release-please reads only X.Y.Z. So v1.1.2 and v1.1.2.0 are one release.
const compareVersion = (a, b) => (a.x - b.x) || (a.y - b.y) || (a.z - b.z);

// The tag a release's changelog starts from: the highest final release tag whose X.Y.Z is
// strictly below the current tag's, read from the repository's tags (never from GitHub
// Releases, so a tag without a Release is found, and resuming an older release finds its
// real predecessor). Of several tags with that X.Y.Z the highest BUILD wins (a four-part
// tag beats the three-part alias). '' when there is none (the first release) or when
// `currentTag` is not a final release tag. `tags` is a list of tag names, not reordered.
function previousReleaseTag(tags, currentTag) {
  const current = parseReleaseTag(currentTag);
  if (!current) return '';
  let best = null;
  for (const name of tags) {
    const parsed = parseReleaseTag(name);
    if (!parsed || compareVersion(parsed, current) >= 0) continue;
    if (!best || compareVersion(parsed, best.parsed) > 0 || (compareVersion(parsed, best.parsed) === 0 && parsed.build > best.parsed.build)) {
      best = { name, parsed };
    }
  }
  return best ? best.name : '';
}

// Does `tag` take the GitHub "Latest" badge? Only a final release whose X.Y.Z is not below
// the X.Y.Z of any other final tag of the repository: resuming an older release must not
// take it, and a prerelease never does. `tags` need not contain `tag` yet.
function makeLatest(tag, tags) {
  if (isPrerelease(tag)) return false;
  const current = parseReleaseTag(tag);
  if (!current) return false;
  return !tags.some((name) => {
    const other = parseReleaseTag(name);
    return other !== null && compareVersion(other, current) > 0;
  });
}

// Rule R4: a package version may be promoted (or reused) only when its code coverage check
// passed and its validation ran. `row` is a Dev Hub row (release-devhub.cjs); a missing or
// unknown (null) field never passes and is reported as unknown. `kind` is the package kind of
// release-package-set.cjs (PACKAGE_KIND): the BYO package has no coverage figure, so
// only its coverage check is waived. A missing or unknown kind throws, so a caller cannot skip
// the rule by accident. Returns the reasons it fails, [] when it passes.
function buildCheckFailures(row, kind) {
  if (!Object.values(PACKAGE_KIND).includes(kind)) throw new Error(`buildCheckFailures needs a package kind (${Object.values(PACKAGE_KIND).join(' or ')}), got ${String(kind)}`);
  const failures = [];
  if (kind !== PACKAGE_KIND.BYO) {
    if (row.hasPassedCoverageCheck === false) failures.push('the code coverage check did not pass');
    else if (row.hasPassedCoverageCheck !== true) failures.push('the code coverage status is unknown');
  }
  if (row.validationSkipped === true) failures.push('validation was skipped');
  else if (row.validationSkipped !== false) failures.push('the validation status is unknown');
  return failures;
}

module.exports = { effectiveNotes, isPrerelease, parseReleaseTag, previousReleaseTag, makeLatest, buildCheckFailures };