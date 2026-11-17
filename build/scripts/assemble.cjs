#!/usr/bin/env node
// =============================================================================
// assemble.cjs - builds the Assembled tree (assembled/) from the two upstream pins and force-app
// =============================================================================
// Run from the repository root after `git submodule update --init --depth 1`:
//   node build/scripts/assemble.cjs                    plan, check, rebuild assembled/, run every guard
//   node build/scripts/assemble.cjs --check-allowlist  guard 1 only (.gitmodules), before any submodule is fetched
// Environment:
//   ASSEMBLED_PATH  output folder, repo-relative (default assembled); refused when absolute, containing .., equal to,
//                   containing or inside a source root, or tracked; git must ignore it (guard 3 checks this path)
//   GITHUB_OUTPUT   when set, `assembled-path=<folder>` is appended to it
// Output: one `::error::<guard>: <item>` line per finding. Exit 0 = no findings, 1 = at least one.
// The modules: assemble-run.cjs (the run: repository in, findings out), tracked-tree.cjs (the git facts),
// assemble-tree.cjs (which files are copied) and assemble-guards.cjs (the five guards).
// =============================================================================

const fs = require('node:fs');
const { assemble } = require('./assemble-run.cjs');
const { gitRepo } = require('./tracked-tree.cjs');

function main(argv, env, repoRoot) {
  const { findings, outputPath } = assemble({
    repoRoot,
    repo: gitRepo(repoRoot),
    out: env.ASSEMBLED_PATH || 'assembled',
    allowlistOnly: argv.includes('--check-allowlist'),
  });
  if (outputPath !== null && env.GITHUB_OUTPUT) fs.appendFileSync(env.GITHUB_OUTPUT, `assembled-path=${outputPath}\n`);
  findings.forEach((line) => console.log(line));
  return findings.length === 0 ? 0 : 1;
}

if (require.main === module) process.exit(main(process.argv.slice(2), process.env, process.cwd()));

module.exports = { main };
