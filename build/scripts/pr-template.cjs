// =============================================================================
// pr-template.cjs - The PR template check: decisions and the sticky comment
// =============================================================================
// The decisions behind pr-template-validation.yml (the required `Validate PR Template`
// check):
//   validatePrTemplate         title format, description and checklist of a PR -> errors,
//                              warnings and the comment text
//   upsertValidationComment    the one comment per PR, found by a hidden marker on its
//                              first line across ALL pages of comments
// The title types are pr-title.cjs; the marker comment lookup is release-comments.cjs.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { TITLE_TYPES, parseTitle } = require('./pr-title.cjs');
const { findMarked } = require('./release-comments.cjs');

// First line of the comment. Only a bot-authored comment with this first line is ours.
const COMMENT_MARKER = '<!-- pr-template-validation -->';

// Skip only PRs a bot authored (pulls API author), never because of the event actor.
function isBotAuthored(pr) {
  return pr.user.type === 'Bot';
}

// Validate a PR read from the pulls API. Returns
// { skipped, valid, errors, warnings, detectedType, commentBody }; a skipped (bot) PR has
// no comment.
function validatePrTemplate(pr) {
  if (isBotAuthored(pr)) {
    return { skipped: true, valid: true, errors: [], warnings: [], detectedType: '', commentBody: '' };
  }

  const body = pr.body || '';
  const errors = [];
  const warnings = [];

  // Description: at least 10 characters, not placeholder text.
  const descriptionSection = body.match(/## Description\s*([\s\S]*?)(?=##|$)/i);
  const description = descriptionSection ? descriptionSection[1].trim() : '';
  const cleanDescription = description.replace(/<!--[\s\S]*?-->/g, '').trim();
  const placeholderPatterns = [
    /^n\/a$/i, /^na$/i, /^none$/i, /^no description$/i,
    /^todo$/i, /^tbd$/i, /^wip$/i, /^-+$/, /^\.+$/,
  ];
  if (cleanDescription.length < 10) {
    errors.push('❌ **Description**: Must be at least 10 characters. Please provide a meaningful description of your changes.');
  } else if (placeholderPatterns.some((pattern) => pattern.test(cleanDescription))) {
    errors.push('❌ **Description**: Placeholder text detected. Please provide a real description of your changes.');
  }

  // Title: conventional commit format.
  const prTitle = pr.title || '';
  const { type: detectedType, valid: titleValid } = parseTitle(prTitle);
  if (!titleValid) {
    errors.push(
      '❌ **PR Title**: Must follow conventional commit format: `<type>: <description>` or `<type>(<scope>): <description>`, with an optional `!` before the colon for a breaking change.\n'
      + `   Valid types (lowercase): ${TITLE_TYPES.map((type) => `\`${type}\``).join(', ')}.\n`
      + `   Current title: \`${prTitle || '(empty)'}\``
    );
  }

  // Checklist: at least one item checked (warning only).
  const checklistSection = body.match(/## Checklist\s*([\s\S]*?)(?=##|$)/i);
  const checklist = checklistSection ? checklistSection[1] : '';
  const checkedItems = (checklist.match(/-\s*\[x\]/gi) || []).length;
  if (checkedItems === 0) {
    warnings.push('⚠️ **Checklist**: No items checked. Please review and check applicable items.');
  }

  let commentBody;
  if (errors.length > 0) {
    commentBody = `## ❌ PR Template Validation Failed\n\nPlease fix the following issues before this PR can be merged:\n\n${errors.join('\n\n')}`;
    if (warnings.length > 0) commentBody += `\n\n### Warnings\n\n${warnings.join('\n\n')}`;
    commentBody += '\n\n---\n*Edit your PR title and/or description to fix these issues. This check will re-run automatically.*';
  } else {
    commentBody = '## ✅ PR Template Validation Passed\n\n';
    commentBody += detectedType
      ? `- **Type**: \`${detectedType}\` *(detected from title)*\n`
      : '- **Type**: ⚠️ Not detected from title\n';
    commentBody += `- **Description**: Valid (${cleanDescription.length} characters)\n`;
    commentBody += `- **Checklist**: ${checkedItems} item(s) checked`;
    if (warnings.length > 0) commentBody += `\n\n### Warnings\n\n${warnings.join('\n\n')}`;
  }

  return {
    skipped: false, valid: errors.length === 0, errors, warnings, detectedType,
    commentBody: `${COMMENT_MARKER}\n${commentBody}`,
  };
}

// Update this check's comment, or create it when there is none yet. Only a bot-authored
// comment whose first line is COMMENT_MARKER counts; comments of any other author, or
// that merely mention the check, are left alone.
async function upsertValidationComment({ github, owner, repo, prNumber, body }) {
  const { comment } = await findMarked({ github, owner, repo, prNumber }, COMMENT_MARKER);
  if (comment) {
    await github.rest.issues.updateComment({ owner, repo, comment_id: comment.id, body });
  } else {
    await github.rest.issues.createComment({ owner, repo, issue_number: prNumber, body });
  }
}

module.exports = { COMMENT_MARKER, isBotAuthored, validatePrTemplate, upsertValidationComment };
