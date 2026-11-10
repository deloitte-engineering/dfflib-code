// =============================================================================
// tracked-tree.cjs - the Tracked tree: what git tracks, behind one interface and two adapters
// =============================================================================
// The readers of the repository's tracked files get their
// git facts here, so a path is listed one way: NUL-separated, never quoted (git quotes a path with
// non-ASCII characters in the plain listing). No dependency outside node: it runs in the assemble
// action before any submodule is fetched.
//
// A repo adapter answers four questions, all as plain data:
//   tracked(folder?)     sorted repo-relative paths; with folder, only that folder's files and the folder itself (a literal path, not a git pathspec)
//   indexEntries(dir)    `git ls-files -s` lines for dir, `<mode> <sha> <stage>\t<path>`, paths unquoted
//   submoduleStatus()    the text of `git submodule status`
//   isIgnored(folder)    whether git ignores a path inside folder (git's own answer, negations included)
// Adapters: gitRepo(root) runs git in root; fixtureRepo({ tracked, index, submodules, ignored }) holds
// the same answers as data, so a test needs no git process.
// gitTree(root) and fixtureTree(text) are the tracked list alone, for a caller that needs nothing else.
// =============================================================================

const { execFileSync } = require('node:child_process');

const within = (folder, file) => file === folder || file.startsWith(`${folder}/`);
const cleanFolder = (folder) => folder.replace(/[\\/]+$/, '');

function gitRepo(root) {
  const git = (...args) => execFileSync('git', ['-C', root, ...args], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'] });
  const nul = (text) => text.split('\0').filter(Boolean);
  // A folder is a literal path, never a git pathspec: `o*` must not match `out/`.
  const literal = (folder) => `:(literal)${cleanFolder(folder)}`;
  return {
    tracked: (folder) => nul(git('ls-files', '-z', ...(folder === undefined ? [] : ['--', literal(folder)]))).sort(),
    indexEntries: (dir) => nul(git('ls-files', '-s', '-z', '--', literal(dir))).join('\n'),
    submoduleStatus: () => git('submodule', 'status'),
    // `git check-ignore -q` exits 0 when the path is ignored and 1 when it is not.
    isIgnored(folder) {
      try {
        git('check-ignore', '-q', '--', `${cleanFolder(folder)}/probe`);
        return true;
      } catch {
        return false;
      }
    },
  };
}

// tracked: array of paths; index and submodules: text; ignored: boolean, or a function of the folder.
function fixtureRepo({ tracked = [], index = '', submodules = '', ignored = false } = {}) {
  const sorted = [...tracked].sort();
  return {
    tracked: (folder) => (folder === undefined ? sorted : sorted.filter((file) => within(cleanFolder(folder), file))),
    indexEntries: () => index,
    submoduleStatus: () => submodules,
    isIgnored: (folder) => (typeof ignored === 'function' ? ignored(folder) : ignored),
  };
}

const gitTree = (root) => gitRepo(root).tracked();

function fixtureTree(text) {
  return text.split('\n').map((line) => line.trim()).filter((line) => line !== '' && !line.startsWith('#')).sort();
}

module.exports = { gitRepo, fixtureRepo, gitTree, fixtureTree };
