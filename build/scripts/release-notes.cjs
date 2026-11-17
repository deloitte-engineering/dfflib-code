// =============================================================================
// release-notes.cjs - The one place that puts the release notes of a version together
// =============================================================================
// notesFor() joins the previous release tag, the merged PRs, the upstream pins, the generated
// notes, the package set header and the effective notes. Required by release-publish.cjs
// (release-publish.yml, publish) and release-override.cjs (release-notes-override.yml,
// the release PR preview); the only difference between the two callers is `compareTo`.
// It never reads the override box: the caller passes the box it already read,
// so the text read before promote is the text published.
// Also owns fenceFor and plainText; installUrls and the one "install links pending" text come
// from release-notes-header.cjs (the header render) and are re-exported.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { effectiveNotes, previousReleaseTag } = require('./release-rules.cjs');
const { githubPinReader, pinsAt } = require('./release-pins.cjs');
const { LINKS_PENDING, installUrls, renderHeader } = require('./release-notes-header.cjs');
const { standaloneFirst } = require('./release-package-set.cjs');

// A code fence longer than any backtick run in `text`, so the text cannot close it.
function fenceFor(text) {
  const longest = Math.max(2, ...(text.match(/`+/g) || []).map((run) => run.length));
  return '`'.repeat(longest + 1);
}

// A collection warning carries API error text (untrusted): one line, no markup, no
// HTML, so it cannot open a heading, a list or a tag in a run summary.
function plainText(text) {
  return String(text)
    .replace(/\s+/g, ' ')
    .replace(/[<>`\[\]]/g, (char) => `\\${char}`)
    .slice(0, 500);
}

// Categories mirror .github/release.yml exactly (no "Others"); unmatched -> misc.
function categorize(rawLabels) {
  const labels = rawLabels.map((l) => l.toLowerCase());
  if (labels.some((l) => l.includes('breaking'))) return 'breaking';
  if (labels.some((l) => ['enhancement', 'feat', 'features'].includes(l))) return 'features';
  if (labels.some((l) => ['bug', 'fix', 'bugfix'].includes(l))) return 'bugs';
  return 'misc';
}

// Files that are pipeline/docs noise, never a Salesforce component.
function isNoise(filePath) {
  if (filePath.endsWith('.md')) return true;
  if (filePath === 'sfdx-project.json') return true;
  return /^(\.github|docs|manifest|dependencies)(\/|$)/.test(filePath);
}

// A PR that only moves submodule pointers (every changed file is under dependencies/). The notes show
// it as the upstream pin lines, never as a bullet.
function isPinBump(files) {
  return files.length > 0 && files.every((file) => /^dependencies(\/|$)/.test(file));
}

// One primary component per PR, by priority; null when no real component.
const COMPONENT_PATTERNS = [
  /classes\/([^/]+)\.cls(?:-meta\.xml)?$/,
  /triggers\/([^/]+)\.trigger(?:-meta\.xml)?$/,
  /lwc\/([^/]+)\//,
  /aura\/([^/]+)\//,
  /objects\/([^/]+)\//,
  /flows\/([^/]+)\.flow/,
];
function getPrimaryComponent(files) {
  for (const pattern of COMPONENT_PATTERNS) {
    for (const file of files) {
      if (isNoise(file)) continue;
      const match = file.match(pattern);
      if (match) return match[1];
    }
  }
  return null;
}

// Strip any conventional-commit prefix (type, scope, `!`) from a PR title.
function cleanTitle(title) {
  return title.replace(/^\w+(\([^)]+\))?!?:\s*/, '');
}

// PR titles are free text from contributors: render them literally. Backslash
// escapes cover the characters that open a tag, link, image, code span or entity
// ("&#64;" would decode to a live "@"). A zero-width space after "@" separates it
// from the login, so a release body or comment neither links nor notifies it.
function escapeText(text) {
  return text
    .replace(/[\\`<>[\]&]/g, (char) => `\\${char}`)
    .replace(/@/g, '@\u200b');
}

// A file-derived component label goes inside a code span, where only a backtick
// is special and cannot be escaped: use a fence longer than any backtick run in
// the label, padded with a space when the label starts or ends with a backtick.
function codeSpan(text) {
  const longest = Math.max(0, ...(text.match(/`+/g) || []).map((run) => run.length));
  const fence = '`'.repeat(longest + 1);
  const pad = text.startsWith('`') || text.endsWith('`') ? ' ' : '';
  return `${fence}${pad}${text}${pad}${fence}`;
}

// Build the release-notes markdown. Pure: no API calls, no I/O.
// `builds` is the package set, [{ package, kind, installId | null }] (release-notes-header.cjs renders it),
// `pins` the [{ name, url, sha, previousSha? }] of pinsAt() ([] shows no upstream bullet).
function buildReleaseNotes(meta) {
  const { versionNumber, builds = [], pins = [], prs, newContributors, previousTag, currentTag, owner, repo } = meta;

  const categories = {
    breaking: { title: '### 🛠 Breaking Changes', prs: [] },
    features: { title: '### 🎉 New features', prs: [] },
    bugs: { title: '### 🐛 Bug fixes', prs: [] },
    misc: { title: '### 📚 Miscellaneous updates', prs: [] },
  };
  for (const pr of prs) {
    categories[categorize(pr.labels)].prs.push(pr);
  }

  let notes = `## **D'fflib v${versionNumber}**\n`;
  notes += `\n${renderHeader({ builds, pins, previousTag })}\n`;
  notes += `## What's Changed\n`;

  for (const key of ['breaking', 'features', 'bugs', 'misc']) {
    const catPrs = categories[key].prs;
    if (catPrs.length === 0) continue;
    notes += `${categories[key].title}\n`;

    const groups = {};
    const flat = [];
    for (const pr of catPrs) {
      const component = getPrimaryComponent(pr.files);
      if (component) {
        (groups[component] = groups[component] || []).push(pr);
      } else {
        flat.push(pr);
      }
    }

    for (const component of Object.keys(groups).sort()) {
      notes += `- [${codeSpan(component)}]\n`;
      for (const pr of groups[component]) {
        notes += `    - ${escapeText(cleanTitle(pr.title))} by @${pr.author} in #${pr.number}\n`;
      }
    }
    for (const pr of flat) {
      notes += `- ${escapeText(cleanTitle(pr.title))} by @${pr.author} in #${pr.number}\n`;
    }
    notes += `\n`;
  }

  if (newContributors.length > 0) {
    notes += `\n### New Contributors\n`;
    for (const contributor of newContributors) {
      notes += `- @${contributor.login} made their first contribution in #${contributor.prNumber}\n`;
    }
    notes += `\n`;
  }

  const changelogUrl = previousTag
    ? `https://github.com/${owner}/${repo}/compare/${previousTag}...${currentTag}`
    : `https://github.com/${owner}/${repo}/commits/${currentTag}`;
  notes += `\n**Full Changelog**: ${changelogUrl}\n`;

  return notes;
}

// The release notes of `version`, for the release PR preview and for publish alike.
//   head        the ref whose merged PRs are listed (the release branch, or the merge commit)
//   compareTo   the ref the changelog link ends at (the release branch, or the release tag)
//   builds      the package set, [{ package, kind, installId | null }] (recordedBetaBuild().builds)
//   tagNames    the names of the repository tags; the previous release tag comes from them
//   box         the override box the caller already read (never read here), or null
//   pinReader   the reader of the upstream pins (release-pins.cjs); default: the GitHub Contents API.
//               The pins are read at `head` and, to say where each one moved, at the previous release tag
//               (for every package set); a failed read is a warning (a failed previous read drops only
//               the compare and unchanged notes), a missing pin is no bullet.
// Returns { base, builds, prs, warnings, generated, effective }: base is the previous release
// tag ('' for a first release), builds the package set (standalone package first), warnings
// what collecting the PRs could not read (plain one-line text), generated the notes built from
// the PRs and effective what the release publishes (null without a box).
async function notesFor({ github, owner, repo, version, head, compareTo = head, builds, tagNames, box, pinReader = githubPinReader({ github, owner, repo }), log = console.log }) {
  const base = previousReleaseTag(tagNames, `v${version}`);
  const packages = standaloneFirst(builds);
  const { prs, newContributors, warnings: collected } = await collectReleasePrs({ github, owner, repo, base, head, log });
  let pins = [];
  try {
    pins = await pinsAt(pinReader, head);
  } catch (error) {
    log(`Error reading the upstream pins: ${error.message}`);
    collected.push(`Could not read the upstream pins at ${head}: ${error.message}`);
  }
  if (pins.length > 0 && base) {
    try {
      const before = await pinsAt(pinReader, base);
      pins = pins.map((pin) => ({ ...pin, previousSha: (before.find((each) => each.path === pin.path) || {}).sha }));
    } catch (error) {
      log(`Error reading the upstream pins at ${base}: ${error.message}`);
      collected.push(`Could not read the upstream pins at ${base}: ${error.message}`);
    }
  }
  const generated = buildReleaseNotes({
    versionNumber: version, builds: packages, pins, prs, newContributors, previousTag: base, currentTag: compareTo, owner, repo,
  });
  const warnings = collected.map(plainText);
  const effective = box ? effectiveNotes({ box, generated: { notes: generated, warnings } }) : null;
  return { base, builds: packages, prs, warnings, generated, effective };
}

// The names of every tag of the repository, through all pages. The previous release tag
// and the Latest badge rule read them; a failed listing is thrown, never read as no tags.
async function listTagNames({ github, owner, repo }) {
  const tags = await github.paginate(github.rest.repos.listTags, { owner, repo, per_page: 100 });
  return tags.map((tag) => tag.name);
}

// The names of every file a PR changes, through all pages (github.paginate is the
// shared pager).
async function listPrFiles(github, owner, repo, number) {
  const files = await github.paginate(github.rest.pulls.listFiles, {
    owner, repo, pull_number: number, per_page: 100,
  });
  return files.map((file) => file.filename);
}

// The data behind the release notes: the releasable (non-bot) merged PRs in the
// range and the first-time contributors. Shared by the publish notes and the
// release PR preview, so the preview can also list PRs an override leaves out.
// Failures are logged and skipped, as publish always did; `warnings` lists what
// could not be read so the preview can show it (publish ignores it).
//
// Which numbers are PRs: only the FIRST LINE of each commit counts, in two
// forms: "Merge pull request #N" and a trailing "(#N)" (squash merge). A "#N"
// elsewhere in the subject, or anywhere in the body ("closes #N"), is an issue
// reference, not a candidate. A candidate whose PR lookup answers 404 is not a PR:
// it is logged once and skipped quietly (no warning). Any other lookup error (rate
// limit, 5xx) is a warning. Changed files come from listPrFiles (every page).
async function collectReleasePrs({ github, owner, repo, base, head, log = console.log }) {
  log(`Generating release notes from ${base || 'beginning'} to ${head}`);
  const warnings = [];

  // Step 1: Get commits in the range to find merged PRs, through every page
  let commits = [];
  try {
    if (base) {
      commits = await github.paginate(github.rest.repos.compareCommits, { owner, repo, base, head, per_page: 100 },
        (response) => response.data.commits);
    } else {
      commits = await github.paginate(github.rest.repos.listCommits, { owner, repo, sha: head, per_page: 100 });
    }
  } catch (error) {
    log(`Error fetching commits: ${error.message}`);
    warnings.push(`Could not list the commits from ${base || 'the beginning'} to ${head}: ${error.message}`);
    commits = [];
  }
  log(`Found ${commits.length} commits`);

  // Step 2: Extract PR numbers from the commit subjects (see the comment above)
  const prNumbers = new Set();
  for (const commit of commits) {
    const subject = commit.commit.message.split(/\r?\n/, 1)[0];
    const match = subject.match(/^Merge pull request #(\d+)/) || subject.match(/\(#(\d+)\)\s*$/);
    if (match) prNumbers.add(parseInt(match[1], 10));
  }
  log(`Found ${prNumbers.size} PRs: ${[...prNumbers].join(', ')}`);

  // Step 3: Fetch PR details and files changed
  const prs = [];
  for (const prNum of prNumbers) {
    try {
      const prData = await github.rest.pulls.get({ owner, repo, pull_number: prNum });
      const files = await listPrFiles(github, owner, repo, prNum);
      prs.push({
        number: prNum,
        title: prData.data.title,
        author: prData.data.user.login,
        labels: prData.data.labels.map((l) => l.name),
        files,
        merged_at: prData.data.merged_at,
      });
    } catch (error) {
      if (error.status === 404) {
        log(`#${prNum} is not a pull request (404) - skipped`);
        continue;
      }
      log(`Error fetching PR #${prNum}: ${error.message}`);
      warnings.push(`Could not read PR #${prNum}: ${error.message}`);
    }
  }
  log(`Fetched details for ${prs.length} PRs`);

  // Step 4: Skip bot-authored PRs (Renovate/Dependabot) and PRs that only move submodule pointers
  // (the upstream pin lines show those) so they don't clutter the notes or the New Contributors list.
  const releasablePrs = prs.filter((pr) => !pr.author.endsWith('[bot]') && !isPinBump(pr.files));
  log(`${releasablePrs.length} of ${prs.length} PRs after excluding bots and submodule bumps`);

  // Step 5: Detect first-time contributors (exactly one merged PR).
  // One search per author: the search API allows only 30 requests a minute.
  const firstPrByAuthor = new Map();
  for (const pr of releasablePrs) {
    if (!firstPrByAuthor.has(pr.author)) firstPrByAuthor.set(pr.author, pr);
  }
  const newContributors = [];
  let checked = 0;
  try {
    for (const [author, pr] of firstPrByAuthor) {
      const authorPrs = await github.rest.search.issuesAndPullRequests({
        q: `repo:${owner}/${repo} is:pr is:merged author:${author}`,
        per_page: 2,
      });
      if (authorPrs.data.total_count === 1) {
        newContributors.push({ login: author, prNumber: pr.number });
      }
      checked += 1;
    }
  } catch (error) {
    log(`Error checking contributors: ${error.message}`);
    const left = firstPrByAuthor.size - checked;
    warnings.push(`Could not check for new contributors (${left} of ${firstPrByAuthor.size} PR authors not checked): ${error.message}`);
  }

  return { prs: releasablePrs, newContributors, warnings };
}

module.exports = {
  LINKS_PENDING,
  installUrls,
  fenceFor,
  plainText,
  categorize,
  isNoise,
  getPrimaryComponent,
  buildReleaseNotes,
  notesFor,
  collectReleasePrs,
  listPrFiles,
  listTagNames,
};
