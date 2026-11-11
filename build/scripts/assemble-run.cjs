// =============================================================================
// assemble-run.cjs - builds the Assembled tree and runs every guard: repository in, findings out
// =============================================================================
// assemble({ repoRoot, repo, out, allowlistOnly }) returns { findings, outputPath }:
//   repoRoot       the repository folder; its files are read here, its git facts come from repo
//   repo           a repo adapter of tracked-tree.cjs (gitRepo(repoRoot) in the command line, fixtureRepo in a test)
//   out            output folder, repo-relative (default monolith)
//   allowlistOnly  run guard 1 (.gitmodules) alone, before any submodule is fetched
//   findings       annotated lines, one per finding, in guard order; empty = pass
//   outputPath     the output folder when the run got to the end, else null (the output is not published)
// A refused output path or a symlink stops the run before anything is written. The command line is
// assemble-monolith.cjs; the modules are assemble-tree.cjs (which files are copied) and
// assemble-guards.cjs (the five guards).
// =============================================================================

const fs = require('node:fs');
const path = require('node:path');
const { plan, sourceRoots, checkOutputPath, write } = require('./assemble-tree.cjs');
const guards = require('./assemble-guards.cjs');

const readIfExists = (file) => (fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '');

function assemble({ repoRoot, repo, out = 'monolith', allowlistOnly = false }) {
  const findings = [];
  const report = (guard, items) => items.forEach((item) => findings.push(guards.annotate(guard, item)));
  const stop = () => ({ findings, outputPath: null });

  report('gitmodules-allowlist', guards.checkGitmodules(readIfExists(path.join(repoRoot, '.gitmodules'))));
  if (allowlistOnly) return stop();

  const refused = checkOutputPath(out, { roots: sourceRoots(repoRoot), tracked: repo.tracked(), repoRoot });
  if (refused) {
    report('output-path', [refused]);
    return stop();
  }

  const planned = plan(repoRoot);
  report('symlinks', planned.errors);
  if (planned.errors.length > 0) return stop();

  report('gitlinks-only', guards.checkGitlinks({ staged: repo.indexEntries('dependencies'), status: repo.submoduleStatus() }));
  const folder = out.replace(/[\\/]+$/, '');
  report('monolith-untracked', guards.checkMonolithUntracked({ folder, tracked: repo.tracked(folder).join('\n'), ignored: repo.isIgnored(folder) }));

  write(repoRoot, out, planned.files);

  // Each file the guards need is read once: labels for the duplicate-name guard, Apex for the twin rule.
  const isApex = (file) => /\.(cls|trigger)$/i.test(file.to);
  const isLabels = (file) => /\.labels-meta\.xml$/i.test(file.to);
  const contentOf = new Map(planned.files.filter((f) => isApex(f) || isLabels(f)).map((f) => [f, fs.readFileSync(f.from, 'utf8')]));
  const inRoot = (file) => file.to.slice(file.root.length + 1);
  report('duplicate-names', guards.checkDuplicateNames(planned.files.map((file) => ({
    source: file.root,
    path: inRoot(file),
    content: isLabels(file) ? contentOf.get(file) : undefined,
  }))));
  report('twin-rule', guards.checkTwins(planned.files.filter(isApex).map((file) => ({ path: file.to, content: contentOf.get(file) }))));

  return { findings, outputPath: folder };
}

module.exports = { assemble };
