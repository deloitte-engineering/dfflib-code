// =============================================================================
// pr-title.cjs - The conventional commit types of a PR title, defined once
// =============================================================================
// The one list of title types and the one parser of a PR title. pr-labels.cjs
// (the conventional label) and pr-template.cjs (the blocking title check) both
// use them, so the two workflows can never accept different titles.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

// Lowercase and case-sensitive. This is exactly the type list release-please hard-codes when it
// splits one message into several commits (src/commit.ts, splitMessages), so a title we accept
// is a type release-please names itself.
const TITLE_TYPES = ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore', 'build', 'ci', 'revert'];

// <type>: <subject>, <type>(<scope>): <subject>, with an optional `!` right before the colon.
const TITLE_PATTERN = new RegExp(`^(${TITLE_TYPES.join('|')})(\\([^)]+\\))?(!)?:\\s+.+`);

// Returns { type, valid, breaking }; type is '' (and breaking false) when the title does not
// follow the format. breaking is the `!` right before the colon.
function parseTitle(title) {
  const match = TITLE_PATTERN.exec(title || '');
  return { type: match ? match[1] : '', valid: Boolean(match), breaking: Boolean(match && match[3]) };
}

module.exports = { TITLE_TYPES, parseTitle };
