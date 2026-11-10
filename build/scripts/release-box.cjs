// =============================================================================
// release-box.cjs - The override box of a release PR and its authority rule
// =============================================================================
// The override box is one bot-created comment whose whole body is the marker. A
// maintainer edits it to override the generated release notes; the bot never
// edits it. Authority is the role of the LAST EDITOR, because a `write` user can
// edit any comment.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { textAfterMarker, findMarked } = require('./release-comments.cjs');
const { checkMaintainer } = require('./release-pr.cjs');

const BOX_MARKER = '<!-- release-notes-override -->';

const BOX_STATE = Object.freeze({ ABSENT: 'absent', EMPTY: 'empty', ACTIVE: 'active', INVALID: 'invalid' });
const INVALID_REASON = Object.freeze({ INSUFFICIENT_ROLE: 'insufficient-role', EDITOR_UNKNOWN: 'editor-unknown' });

/**
 * @typedef {object} Box
 * @property {string} state     one of BOX_STATE
 * @property {string|null} reason  one of INVALID_REASON when invalid, else null
 * @property {string|null} editor  login of the last editor, null when never edited
 * @property {string} body      the text after the marker line
 * @property {string|null} url  link to the box comment
 * @property {string|null} updatedAt  REST updated_at of the box comment
 * @property {number|null} id   REST id of the box comment
 * @property {number} outside   marker comments that are not the box
 */

// Every box has the same keys, whatever its state, so callers never meet a
// missing field.
/** @returns {Box} */
function makeBox({ state, reason = null, editor = null, body = '', url = null, updatedAt = null, id = null, outside = 0 }) {
  return { state, reason, editor, body, url, updatedAt, id, outside };
}

// The text after the marker line ('' when there is none), or null when the first
// line is not the marker.
function parseBoxBody(raw) {
  return textAfterMarker(raw, BOX_MARKER);
}

const EDITOR_QUERY = `query($id: ID!) {
  node(id: $id) { ... on IssueComment { lastEditedAt editor { __typename login } } }
}`;

// The last editor of a comment (GraphQL `editor`), or null when it was never edited.
async function lastEditor(github, commentNodeId) {
  const { node } = await github.graphql(EDITOR_QUERY, { id: commentNodeId });
  return (node && node.editor) || null;
}

// Read the override box of a release PR. The box is the oldest bot-authored
// comment whose first line is the marker; every other marker comment is only
// counted in `outside`. The bot never edits the box, so the last editor is
// always a human (or the box is untouched and empty).
// Returns a Box (see makeBox).
// A bot editor (for example an edit with GITHUB_TOKEN) is invalid.
// API failures throw: a failed lookup must not turn into an invalid box.
async function readBox({ github, owner, repo, prNumber }) {
  const { comment, others: outside } = await findMarked({ github, owner, repo, prNumber }, BOX_MARKER);
  if (!comment) return makeBox({ state: BOX_STATE.ABSENT, outside });

  const text = parseBoxBody(comment.body);
  const found = { id: comment.id, url: comment.html_url, updatedAt: comment.updated_at, body: text, outside };
  if (text === '') return makeBox({ ...found, state: BOX_STATE.EMPTY });

  const editor = await lastEditor(github, comment.node_id);
  if (!editor) return makeBox({ ...found, state: BOX_STATE.INVALID, reason: INVALID_REASON.EDITOR_UNKNOWN });
  found.editor = editor.login;
  if (editor.__typename !== 'User') return makeBox({ ...found, state: BOX_STATE.INVALID, reason: INVALID_REASON.INSUFFICIENT_ROLE });

  const { allowed } = await checkMaintainer({ github, owner, repo, login: editor.login });
  return allowed
    ? makeBox({ ...found, state: BOX_STATE.ACTIVE })
    : makeBox({ ...found, state: BOX_STATE.INVALID, reason: INVALID_REASON.INSUFFICIENT_ROLE });
}

// Make sure the release PR has an override box: post the empty one (the marker
// only) when none exists, also after a human deleted it. The bot never edits an
// existing box. Returns { created, box } with `box` as readBox() reports it. A new
// box is built from the create response, not read back: the comment list can lag
// behind a create, which would report the box as absent again.
async function ensureBox({ github, owner, repo, prNumber }) {
  const existing = await readBox({ github, owner, repo, prNumber });
  if (existing.state !== BOX_STATE.ABSENT) return { created: false, box: existing };
  const { data } = await github.rest.issues.createComment({ owner, repo, issue_number: prNumber, body: BOX_MARKER });
  const box = makeBox({ state: BOX_STATE.EMPTY, id: data.id, url: data.html_url, updatedAt: data.updated_at, outside: existing.outside });
  return { created: true, box };
}

module.exports = { BOX_MARKER, BOX_STATE, INVALID_REASON, makeBox, parseBoxBody, readBox, ensureBox };