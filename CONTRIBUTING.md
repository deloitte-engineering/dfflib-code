# Contributing to D'fflib

Thank you for contributing to D'fflib. This guide takes you from a clone to a merged pull request. To install the packages instead, see the [README](README.md). Ask questions, report bugs and propose changes in this repository's Issues.

## Code style and hygiene

- Match the style of the file you change.
- Give new classes in `force-app/` the `dfflib_` prefix.
- Include unit tests for new functionality.
- Update the documentation when behaviour changes.
- Change source under `force-app/` only. Never edit `dependencies/` (the upstream fflib libraries) or `monolith/` (built for you) by hand.
- Write every commit as a [conventional commit](#commit-messages), and fold corrections to your own branch into the commit they correct before you push (see [Fixups](#fixups-before-the-first-push)).

## Getting started

You need Git and Node.js. The Salesforce CLI (`sf`) and an org you can deploy to are optional: your pull request is validated for you.

| Step | Command | Why |
|---|---|---|
| 1. Clone with submodules | `git clone --recurse-submodules --shallow-submodules <repository-url>`<br>`cd <repository-folder>`<br>`git config submodule.recurse true` | Fetches the two upstream fflib libraries into `dependencies/`, and keeps them on the commits each branch pins when you switch or pull |
| 2. Assemble | `node build/scripts/assemble-monolith.cjs` | Builds the Assembled tree and runs the guards that the pull request runs too |
| 3. Validate (optional) | `sf project deploy validate --source-dir monolith --test-level RunLocalTests --target-org <alias> --wait 60` | Runs the same deployment validation, with tests, as the pull request check |

The Assembled tree (`monolith/`) is our `force-app/` source plus the pinned upstream fflib sources: it is what the Monolith package is built from.

<details>
<summary>More on the setup</summary>

- A clone made without `--recurse-submodules` needs `git submodule update --init --depth 1` before step 2. The command does nothing after `--recurse-submodules`.
- Run step 2 again after a branch moves an Upstream pin. When you switch between branches that pin different upstream commits, `git status` shows a submodule as modified until it is checked out at the new pin: with `submodule.recurse true` the switch does it, otherwise run `git submodule update --init --depth 1` after the switch.
- `git add dependencies/` stages a pin, so never run it by accident.
- The script deletes and rebuilds `monolith/` (gitignored, never edited by hand) and runs the guards: it prints one `::error::` line per finding and exits 1 when there is any. The guards fail a duplicate class name and a `dfflib_` class that references an `fflib_` class which has a `dfflib_` twin.
- `MONOLITH_PATH` changes the output folder (a repo-relative path that is not a source folder and that git ignores).
- There is no `package.json`, so there is no `npm run` shortcut. No formatter, lint or analyser config exists for Apex, so nothing excludes `dependencies/` or `monolith/`.
- The deployment validation enforces 75% code coverage.

</details>

## Workflow

1. Fork the repository. If you have write access to this repository, you can push your branch here instead; the steps are the same.
1. Create a branch named `feature/<DD-MM-YYYY>-<issue>-<description>`: today's date, the issue number (leave it out when there is none) and a short hyphenated description:
   ```bash
   git checkout -b feature/13-11-2026-42-add-selector-filter
   ```
1. Change source under `force-app/` and commit it, following [Commit messages](#commit-messages).
1. Assemble and, if you like, validate (steps 2 and 3 of [Getting started](#getting-started)).
1. Push the branch.
1. Open a pull request against `main`, with a title and description as in [Pull request title and description](#pull-request-title-and-description). Fill in the template.
1. Make sure every check passes. The code owners are requested for review automatically (see `CODEOWNERS`), and labels are applied for you.

On a pull request from a fork, the `validate-project` check fails. That is expected: a Maintainer validates your change before it merges. If you validated it against your own org (step 3 of [Getting started](#getting-started)), say so in the description.

## Commit messages

Release automation reads every commit that lands on `main`, branch commits included, so the type of each commit matters. Write the subject line as:

```
<type>: <description>
<type>(<scope>): <description>
<type>!: <description>
<type>(<scope>)!: <description>
```

### Types

| Type | Use it for | Auto-applied label | Appears in release notes as |
|---|---|---|---|
| `feat` | A new capability for package users | `enhancement` | New features |
| `fix` | A bug that package users could hit | `bug` | Bug fixes |
| `docs` | Documentation only | *(none)* | Miscellaneous updates |
| `style` | Formatting, with no change in behaviour | `style` | Miscellaneous updates |
| `refactor` | A code change with no change in behaviour | `refactor` | Miscellaneous updates |
| `perf` | A performance improvement | `performance` | Miscellaneous updates |
| `test` | Tests only | *(none)* | Miscellaneous updates |
| `chore` | Maintenance | `chore` | Miscellaneous updates |
| `build` | Build scripts and packaging | *(none)* | Miscellaneous updates |
| `ci` | Workflows | *(none; `ci` comes from the file-based labeler)* | Miscellaneous updates |
| `revert` | Reverting an earlier commit | *(none)* | Miscellaneous updates |

The label is applied from the pull request title (see [How the checks work](#how-the-checks-work)), and the release notes group pull requests by label.

- **The type describes the change to the package.** `feat` is a new capability for package users; `fix` is a bug users could hit. Supporting steps on the same branch use `test`, `refactor`, `docs`, `chore` or `ci`.
- **The highest type decides the version bump**: a breaking change gives a major, `feat` a minor, anything else a patch. One stray `feat:` in a bug-fix branch makes a minor release.
- **A breaking change** puts `!` right before the colon (`feat!:`, `fix!:`, `refactor!:` ...) and/or adds a `BREAKING CHANGE: <what breaks>` footer. It is listed under Breaking Changes.
- **Non-conventional commits** (`wip`, `tweak`) are ignored by release automation; squash them before pushing.

### Scope

A scope is optional in a commit subject: a short noun in parentheses right after the type. Leave it out of pull request titles.

```
feat(selectors): add dynamic field filtering
fix(triggers): handle missing related record gracefully
```

Common scopes in this project: `triggers`, `selectors`, `services`, `domains`, `mocks`, `lwc`, `ci`, `deps`.

### Subject rules

1. **Lowercase type**: `feat:` is valid, `Feat:` and `FEAT:` are not
1. **Colon and space required**: `feat: description` is valid, `feat:description` and `feat - description` are not
1. **Description required**: the subject must not end after the colon
1. **Imperative mood**: write "add feature", not "added feature" or "adds feature"
1. **No period at the end**
1. **Breaking marker only before the colon**: `feat!: ...` and `fix(uow)!: ...` are valid, `!feat: ...`, `feat!(uow): ...` and `feat:! ...` are not
1. **At most ~72 characters**: put extra detail in the body

Examples:

```
feat: add opportunity scoring algorithm
fix(triggers): resolve null pointer in AccountTriggerHandler
docs: update the README install steps
refactor(selectors): simplify SOQL builder interface
feat(selectors)!: drop the deprecated selectSObjectsById overload
```

### Fixups before the first push

Correct your own branch's mistakes with fixups, not `fix:` commits. A bug that only ever existed on your branch is not a fix for users:

```bash
git commit --fixup=<sha>                 # recorded as "fixup! <original subject>"
git rebase -i --autosquash origin/main   # folds it into <sha>
```

Do this before the first push. After that it needs `git push --force-with-lease` on your own branch.

### Body

The body is optional: explain why, wrapped at 72 characters.

```
feat(selectors): add dynamic field filtering

Let callers pass a field set at runtime instead of overriding
getSObjectFieldList().
```

## Pull request title and description

- **Title**: the commit subject format from [Commit messages](#commit-messages), without a scope. On a single-commit branch GitHub pre-fills the title from the commit subject; on a single-commit branch or a squash merge, keep the title and the commit subject identical (so leave the scope out of that commit too). The `pr-template-validation` check fails a title that does not follow the format.
- **Description**: at least 10 characters that say what changed, why, and how you tested it. Placeholder text such as `todo`, `tbd`, `wip`, `n/a`, `none` or only dashes fails the check. Fill in the template and keep its `## Description` and `## Checklist` headings: the check reads those two.

```
feat: add opportunity scoring algorithm
fix: resolve null pointer in AccountTriggerHandler
```

## How the checks work

<details>
<summary>The checks on your pull request, and how to fix a failure</summary>

- **`assemble-guards`** runs on every pull request. It fails when the guards find a problem; step 2 of [Getting started](#getting-started) shows the same findings locally.
- **`validate-project`** runs when a pull request changes the package source, the upstream pins or the project configuration. It deploys the change with all local tests, which must reach 75% code coverage; step 3 of [Getting started](#getting-started) runs the same validation. On a fork it fails (see [Workflow](#workflow)).
- **`pr-template-validation`** fails a title that is not a conventional commit, and a description that is too short or placeholder text. It re-runs when you edit the title or description.
- **`pr-labels`** applies the label for the title type (the label column of the [types table](#types)), and `breaking` for a breaking change. Correct the title and the labels follow.
- **`Release readiness`** passes on every contributor pull request.

</details>
