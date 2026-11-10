// =============================================================================
// release-pins.cjs - The upstream pins of a ref
// =============================================================================
// The one module that says which upstream commit each submodule points to at a ref. pinsAt() asks
// a reader for each allowed submodule path (assemble-guards.cjs SUBMODULES) on its own, never a
// listing of the root. A pin missing at the ref (an old release without submodules, or a path that
// is not a submodule) gives no entry: no error, no placeholder.
// A reader is { readPin(ref, path) -> sha | null }. Two adapters meet the same contract:
//   githubPinReader  the GitHub Contents API (GET /contents/<path>?ref=<ref> answers `type: submodule`
//                    and the pinned `sha`); what the workflows use, so no checkout is needed
//   gitPinReader     local git (git ls-tree: a gitlink has mode 160000); for a checkout
// Used by release-notes.cjs (notesFor: the "Incl." pins in the Notes cell of the unlocked row of the
// notes table, in the notes of the preview and publish; read at the head ref and at the previous release tag).
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const { execFileSync } = require('node:child_process');
const { SUBMODULES } = require('./assemble-guards.cjs');

const GITLINK_MODE = '160000';
const COMMIT_ID = /^[0-9a-f]{40}$/;

// The pins at `ref`: [{ name, path, url, sha }] in the order of SUBMODULES, only those found.
// An answer that is not a full commit id is thrown: it goes into a link, so it is never passed on.
async function pinsAt(reader, ref) {
  const pins = [];
  for (const { path, url } of SUBMODULES) {
    const sha = await reader.readPin(ref, path);
    if (!sha) continue;
    if (!COMMIT_ID.test(sha)) throw new Error(`${path} at ${ref} is pinned to something that is not a commit id`);
    pins.push({ name: path.split('/').pop(), path, url, sha });
  }
  return pins;
}

// The Contents API adapter. 404 (no such path or ref) and any type other than `submodule` give null;
// every other failure is thrown, never read as no pin.
function githubPinReader({ github, owner, repo }) {
  return {
    async readPin(ref, path) {
      try {
        const { data } = await github.rest.repos.getContent({ owner, repo, path, ref });
        return !Array.isArray(data) && data.type === 'submodule' ? data.sha : null;
      } catch (error) {
        if (error.status === 404) return null;
        throw error;
      }
    },
  };
}

// The local git adapter, for the repository at `cwd`. A path that is not there, or not a gitlink, gives null.
function gitPinReader({ cwd }) {
  return {
    async readPin(ref, path) {
      if (ref.startsWith('-')) throw new Error(`${ref} is not a ref`);
      const line = execFileSync('git', ['ls-tree', ref, '--', path], { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
      const match = /^(\d+) commit ([0-9a-f]{40})\t/.exec(line);
      return match && match[1] === GITLINK_MODE ? match[2] : null;
    },
  };
}

module.exports = { pinsAt, githubPinReader, gitPinReader };
