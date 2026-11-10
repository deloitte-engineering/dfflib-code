// =============================================================================
// release-comments.cjs - PR comment helpers shared by the release PR modules
// =============================================================================
// Hidden-marker comments: the first line of the body is an HTML comment that
// identifies the comment, and only comments created by a bot count. Used by
// release-box.cjs (override box), release-preview.cjs (sticky preview) and
// release-label.cjs (stale beta build comment).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

// All comments of a PR (or issue), paginated.
async function listComments({ github, owner, repo, prNumber }) {
  return github.paginate(github.rest.issues.listComments, {
    owner, repo, issue_number: prNumber, per_page: 100,
  });
}

// The text after the marker line, trimmed ('' when there is none), or null when
// the first line of `raw` is not exactly `marker`. The first line is trimmed
// (which also strips a leading BOM) and compared case-sensitively; CRLF is
// normalised so the text is stable.
function textAfterMarker(raw, marker) {
  const lines = (raw || '').replace(/\r\n?/g, '\n').split('\n');
  if (lines[0].trim() !== marker) return null;
  return lines.slice(1).join('\n').trim();
}

// Comments whose first line is the marker, whoever wrote them.
function withMarker(comments, marker) {
  return comments.filter((comment) => textAfterMarker(comment.body, marker) !== null);
}

// The oldest comment created by a bot (REST `user.type`; the REST login is
// `github-actions[bot]` but the GraphQL login is `github-actions`), or undefined.
function oldestBotComment(comments) {
  return comments
    .filter((comment) => comment.user && comment.user.type === 'Bot')
    .sort((a, b) => (Date.parse(a.created_at) - Date.parse(b.created_at)) || (a.id - b.id))[0];
}

// The comment that carries `marker` and how many other comments carry it. The
// comment is the oldest bot-authored match (undefined when there is none); the
// others, whoever wrote them, are only counted.
// `ctx` is { github, owner, repo, prNumber }. Returns { comment, others }.
async function findMarked(ctx, marker) {
  const marked = withMarker(await listComments(ctx), marker);
  const comment = oldestBotComment(marked);
  return { comment, others: marked.length - (comment ? 1 : 0) };
}

module.exports = { listComments, textAfterMarker, withMarker, oldestBotComment, findMarked };