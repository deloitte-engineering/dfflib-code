// =============================================================================
// release-preview.cjs - The sticky release notes preview comment
// =============================================================================
// One bot-only comment on the release PR, found by its hidden first line and the
// Bot author type and edited in place. renderPreview() is pure; upsertPreview()
// is the only function that talks to GitHub. The install lines and the pending text come from
// release-notes-header.cjs (the same package set the notes header renders); fenceFor and
// plainText live in release-notes.cjs.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { findMarked } = require('./release-comments.cjs');
const { BOX_STATE, INVALID_REASON } = require('./release-box.cjs');
const { fenceFor } = require('./release-notes.cjs');
const { installLines } = require('./release-notes-header.cjs');
const { effectiveNotes } = require('./release-rules.cjs');

const PREVIEW_MARKER = '<!-- release-notes-preview -->';
const MAX_COMMENT_LENGTH = 65536; // GitHub's limit for a comment body
const MAX_LISTED_PRS = 20;


// Merged PRs the override text does not mention (as "#N" or in a PR link).
// A warning only: owners prune PRs through the override on purpose.
function findDrift(prs, overrideBody) {
  const text = overrideBody || '';
  return prs.filter((pr) => !new RegExp(`(?:#|/pull/)${pr.number}(?!\\d)`).test(text));
}


// Close a code fence the text leaves open, so it cannot swallow the markup after it.
function closeOpenFences(text) {
  let open = 0;
  for (const line of text.split('\n')) {
    const match = line.match(/^ {0,3}(`{3,})(.*)$/);
    if (!match) continue;
    if (open === 0) open = match[1].length;
    else if (match[1].length >= open && match[2].trim() === '') open = 0;
  }
  return open === 0 ? text : `${text}\n${'`'.repeat(open)}`;
}

function statusLine(box) {
  if (box.state === BOX_STATE.ACTIVE) {
    return `**Override: active.** The text of the [override box](${box.url}), last edited by @${box.editor}, is published instead of the generated notes.`;
  }
  if (box.state === BOX_STATE.INVALID) {
    const why = box.reason === INVALID_REASON.EDITOR_UNKNOWN
      ? 'the last editor of the box could not be determined'
      : `the last edit was by @${box.editor}, who does not have the maintain or admin role`;
    return `**Override: invalid.** In the [override box](${box.url}) ${why}. The promote step will refuse to publish until a maintainer makes a real change to the box and saves it. The generated notes are shown below for reference.`;
  }
  if (box.state === BOX_STATE.EMPTY) return `**Override: none.** The [override box](${box.url}) is empty, so the generated notes apply.`;
  return '**Override: none.** There is no override box yet; the next run creates it.';
}

function howTo(box) {
  if (box.state === BOX_STATE.ACTIVE) {
    return `Edit the [override box](${box.url}) to change the override; empty it to go back to the generated notes.`;
  }
  return [
    `**How to override:** edit the [override box](${box.url}) (the comment by github-actions with the hidden marker) and write the FULL release notes below its first line.`,
    'Only the maintain and admin roles count, and the last person to edit the box decides. Make a real change and save. Whoever writes it owns the whole text. Empty the box to use the generated notes again.',
    'The generated notes are in the collapsed block at the end: copy them as a starting point.',
  ].join('\n');
}

function plural(count, word) {
  return `${count} ${word}${count === 1 ? '' : 's'}`;
}

function driftWarning(drift) {
  const listed = drift.slice(0, MAX_LISTED_PRS).map((pr) => `#${pr.number}`).join(', ');
  const more = drift.length > MAX_LISTED_PRS ? ` and ${drift.length - MAX_LISTED_PRS} more` : '';
  return `- The override does not mention ${plural(drift.length, 'merged PR')}: ${listed}${more} (warning only).`;
}

function warningLines({ box, drift, warnings }) {
  const lines = warnings.map((warning) => `- ${warning}`);
  if (box.outside > 0) {
    lines.push(`- ${plural(box.outside, 'other comment')} with the override marker ${box.outside === 1 ? 'is' : 'are'} ignored: only the override box counts.`);
  }
  if (box.state === BOX_STATE.ACTIVE && drift.length > 0) lines.push(driftWarning(drift));
  return lines;
}

// Everything above the effective notes: marker, title, status, install line,
// warnings and how-to. Always kept, whatever the size of the notes.
function renderHead({ version, box, drift, builds, warnings }) {
  const lines = [PREVIEW_MARKER, `## Release notes preview - v${version}`, '', statusLine(box), '', installLines(builds), ''];
  const warned = warningLines({ box, drift, warnings });
  if (warned.length > 0) lines.push('**Warnings**', ...warned, '');
  lines.push(howTo(box), '', '---', '');
  return lines.join('\n');
}

function renderRawBlock(generated) {
  const fence = fenceFor(generated);
  return `\n<details>\n<summary>Generated notes (copy-paste starting point)</summary>\n\n${fence}markdown\n${generated.trimEnd()}\n${fence}\n\n</details>\n`;
}

// Build the sticky preview comment. Pure: no API calls.
// Inputs: version ('1.2.0'), generated (markdown from buildReleaseNotes), box (as
// readBox() reports it), drift (merged PRs an active override does not mention),
// builds (the package set of notesFor(): { package, kind, installId | null } per package), warnings
// (what collecting the PRs could not read), maxLength.
// Order: marker, status and warnings, effective notes, collapsed raw generated
// notes. Over the limit, the raw block goes first, then the effective notes are
// cut at a line boundary; the head always survives (and is cut only when it alone
// exceeds the limit).
function renderPreview({ version, generated, box, drift = [], builds, warnings = [], maxLength = MAX_COMMENT_LENGTH }) {
  const head = renderHead({ version, box, drift, builds, warnings });
  const heading = '### Effective release notes\n\n';
  const notes = effectiveNotes({ box, generated: { notes: generated, warnings } });
  const effective = notes.source === 'override' ? closeOpenFences(notes.text.trimEnd()) : notes.text.trimEnd();

  const full = `${head}${heading}${effective}\n${renderRawBlock(generated)}`;
  if (full.length <= maxLength) return full;

  const pointer = '\n\n_Shortened to fit the comment size limit: the full text is in the run summary of the workflow run._\n';
  const lines = effective.split('\n');
  const shortened = () => `${head}${heading}${closeOpenFences(lines.join('\n'))}${pointer}`;
  while (lines.length > 0 && shortened().length > maxLength) lines.pop();
  return shortened().slice(0, maxLength);
}

// Line endings and trailing whitespace never count as a change of the preview.
function normalise(text) {
  return text.replace(/\r\n?/g, '\n').trimEnd();
}

// Post or refresh the one bot preview comment: the oldest match is edited in
// place, an identical body is skipped, and one is created when missing.
// Returns { action: 'created' | 'updated' | 'unchanged', id }.
async function upsertPreview({ github, owner, repo, prNumber, body }) {
  const { comment: existing } = await findMarked({ github, owner, repo, prNumber }, PREVIEW_MARKER);
  if (!existing) {
    const { data } = await github.rest.issues.createComment({ owner, repo, issue_number: prNumber, body });
    return { action: 'created', id: data.id };
  }
  if (normalise(existing.body) === normalise(body)) return { action: 'unchanged', id: existing.id };
  await github.rest.issues.updateComment({ owner, repo, comment_id: existing.id, body });
  return { action: 'updated', id: existing.id };
}

module.exports = { PREVIEW_MARKER, findDrift, renderPreview, upsertPreview };