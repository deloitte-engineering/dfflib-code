// =============================================================================
// assemble-tree.cjs - the Assembled tree: which files of the upstream pins and force-app are copied
// =============================================================================
// plan(repoRoot) reads the repository (read-only) and returns { files, errors }:
//   files:  [{ from, to, root }] absolute source path, repo-relative destination path, repo-relative source root
//   errors: [string] reasons the tree must not be assembled
// The destination mirrors the repo-relative source path, so two sources can never collide on disk
// (name clashes between sources are the duplicate-name guard's job, assemble-guards.cjs).
// Copied: dependencies/<upstream>/sfdx-source/<package>/main and /test, and every folder of force-app.
// Not copied: anything else in an upstream repo (project file, .github, config, docs, images).
// =============================================================================

const fs = require('node:fs');
const path = require('node:path');

const toPosix = (p) => p.split(path.sep).join('/');

// Folder names, symlinks included: a symlinked folder must reach plan() so it can be refused, not silently dropped.
function listDirs(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory() || e.isSymbolicLink()).map((e) => e.name).sort();
}

// The repo-relative parts of rel (a/b/c gives a, a/b, a/b/c) that are symlinks. The walk ends at the
// first part that does not exist (or whose parent is a file): nothing below it can be a link.
function symlinkedParts(repoRoot, rel) {
  const parts = rel.split('/');
  const linked = [];
  for (let i = 1; i <= parts.length; i += 1) {
    const sub = parts.slice(0, i).join('/');
    let stat;
    try {
      stat = fs.lstatSync(path.join(repoRoot, sub));
    } catch (error) {
      if (error.code === 'ENOENT' || error.code === 'ENOTDIR') break;
      throw error;
    }
    if (stat.isSymbolicLink()) linked.push(sub);
  }
  return linked;
}

// The source roots, repo-relative and POSIX-style.
function sourceRoots(repoRoot) {
  const roots = [];
  for (const upstream of listDirs(path.join(repoRoot, 'dependencies'))) {
    const sfdxSource = path.join(repoRoot, 'dependencies', upstream, 'sfdx-source');
    for (const pkg of listDirs(sfdxSource)) {
      for (const kind of ['main', 'test']) {
        if (fs.existsSync(path.join(sfdxSource, pkg, kind))) roots.push(`dependencies/${upstream}/sfdx-source/${pkg}/${kind}`);
      }
    }
  }
  if (fs.existsSync(path.join(repoRoot, 'force-app'))) roots.push('force-app');
  return roots;
}

// Collects regular files into out and symlinks into links; a symlink is never followed or copied.
function walk(dir, out, links) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const full = path.join(dir, entry.name);
    if (entry.isSymbolicLink()) links.push(full);
    else if (entry.isDirectory()) walk(full, out, links);
    else out.push(full);
  }
}

// Symlinks at the levels the source roots are discovered from: dependencies/<upstream>, its sfdx-source and each package.
function discoveryLinks(repoRoot) {
  const found = [];
  const linkedIn = (rel) => {
    const dir = path.join(repoRoot, rel);
    if (!fs.existsSync(dir) || !fs.lstatSync(dir).isDirectory()) return [];
    return fs.readdirSync(dir, { withFileTypes: true }).filter((e) => e.isSymbolicLink()).map((e) => `${rel}/${e.name}`);
  };
  found.push(...linkedIn('dependencies'));
  for (const upstream of listDirs(path.join(repoRoot, 'dependencies'))) {
    found.push(...linkedIn(`dependencies/${upstream}`).filter((p) => p.endsWith('/sfdx-source')));
    found.push(...linkedIn(`dependencies/${upstream}/sfdx-source`));
  }
  return found;
}

function plan(repoRoot) {
  const files = [];
  const errors = [];
  for (const link of discoveryLinks(repoRoot)) errors.push(`symlink in a source root: ${link}`);
  for (const root of sourceRoots(repoRoot)) {
    const linkedParts = symlinkedParts(repoRoot, root);
    if (linkedParts.length > 0) {
      errors.push(`symlink in a source root: ${linkedParts[0]}`);
      continue;
    }
    const found = [];
    const links = [];
    walk(path.join(repoRoot, root), found, links);
    for (const link of links) errors.push(`symlink in a source root: ${toPosix(path.relative(repoRoot, link))}`);
    for (const from of found) files.push({ from, to: toPosix(path.relative(repoRoot, from)), root });
  }
  return { files, errors };
}

// The output folder is deleted and rebuilt, so a bad path would delete real sources. Returns null when the
// path is safe, otherwise the reason. roots: the repo-relative source roots; tracked: repo-relative tracked files;
// repoRoot: the repository folder, where every existing part of the path is checked for a symlink or junction.
function checkOutputPath(out, { roots, tracked, repoRoot }) {
  if (typeof out !== 'string' || out.trim() === '') return 'the output path is empty';
  if (/[\u0000-\u001f\u007f]/.test(out)) return 'the output path contains a control character';
  if (path.posix.isAbsolute(out) || path.win32.isAbsolute(out) || /^[A-Za-z]:/.test(out)) return `the output path is absolute or drive-relative: ${out}`;
  const segments = out.split(/[\\/]+/);
  if (segments.includes('..')) return `the output path contains "..": ${out}`;
  const clean = segments.filter((s) => s !== '' && s !== '.').join('/');
  if (clean === '') return 'the output path is the repo root';
  const within = (outer, inner) => inner === outer || inner.startsWith(`${outer}/`);
  for (const root of roots) {
    if (within(clean, root)) return `the output path equals or contains the source root ${root}`;
    if (within(root, clean)) return `the output path is inside the source root ${root}`;
  }
  if (tracked.some((file) => within(clean, file))) return `the output path is, or contains, a tracked path: ${clean}`;
  const linkedParts = symlinkedParts(repoRoot, clean);
  if (linkedParts.length > 0) return `the output path goes through a symlink: ${linkedParts[0]}`;
  return null;
}

// Deletes outDir (repo-relative, already accepted by checkOutputPath) and rebuilds it from the planned files.
function write(repoRoot, outDir, files) {
  const target = path.join(repoRoot, outDir);
  fs.rmSync(target, { recursive: true, force: true });
  for (const { from, to } of files) {
    const dest = path.join(target, to);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(from, dest);
  }
}

module.exports = { plan, sourceRoots, checkOutputPath, write };
