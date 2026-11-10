// =============================================================================
// release-content-tag.cjs - The content tag of a ref
// =============================================================================
// The one module that says what a beta build is built from and hashes it: the content inputs
// (CONTENT_INPUTS, CONTENT_DIRS) and the content tag (contentTag). The plan, the recorded beta build
// state, the publish guard and beta-build.yml all take the tag from here. It reads a ref only through
// the injected `reads.objectAt`, so it has no GitHub or git dependency of its own.
// Used by release-record.cjs (the state), release-publish.cjs (the guard) and beta-build.yml (the plan).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const crypto = require('node:crypto');

// The content inputs: what a beta build is built from and the content tag hashes. The content roots
// (force-app/, dependencies/), the .gitmodules pins and the assemble scripts (the same files the
// validate-project filter names). Never the generated monolith/ path: it is not in git. A new assemble
// script must be added here. This is the one list of content inputs.
const CONTENT_DIRS = ['force-app', 'dependencies'];
const CONTENT_INPUTS = [
  ...CONTENT_DIRS,
  '.gitmodules',
  'build/scripts/assemble-guards.cjs',
  'build/scripts/assemble-monolith.cjs',
  'build/scripts/assemble-run.cjs',
  'build/scripts/assemble-tree.cjs',
  'build/scripts/tracked-tree.cjs',
];

// The content tag of `ref`: one hash of the ids (tree or blob) of the content inputs, in path order.
// `reads.objectAt(ref, path)` returns the id of a path at a ref, or null when it is not there. A missing
// dependencies/, .gitmodules or script is part of the hash (removing one changes the tag); a missing
// force-app gives null: no tag, never a guess.
async function contentTag(reads, ref) {
  const lines = [];
  for (const path of [...CONTENT_INPUTS].sort()) {
    const id = await reads.objectAt(ref, path);
    if (path === 'force-app' && !id) return null;
    lines.push(`${path} ${id || '-'}`);
  }
  return crypto.createHash('sha1').update(`${lines.join('\n')}\n`).digest('hex');
}

module.exports = { CONTENT_DIRS, CONTENT_INPUTS, contentTag };
