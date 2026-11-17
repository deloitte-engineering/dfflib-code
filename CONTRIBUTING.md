# Contributing to D'fflib

Thank you for contributing to D'fflib. This guide takes you from a clone to a merged pull request, including guidelines and standards. To install the packages instead, see the [README](README.md). Questions, bugs or feature requests can be posted in this repository's Issues.

## Table of contents

- [Code style and hygiene](#code-style-and-hygiene)
- [Local setup](#local-setup)
- [Workflow](#workflow)
  - [Branch name](#branch-name)
  - [Commit messages](#commit-messages)
    - [Subject rules](#subject-rules)
    - [Body rules](#body-rules)
    - [Types](#types)
    - [Scope](#scope)
    - [Fixups before the first push](#fixups-before-the-first-push)
  - [Pull request title and description](#pull-request-title-and-description)
    - [Pull request validations](#pull-request-validations)

## Code style and hygiene

- Match the style of the file you change.
- New classes in `force-app/` should have a `dfflib_` prefix.
- Each new functionality should be unit tested.
- Update the documentation when behaviour changes.
- Never edit `dependencies/` (the upstream fflib libraries) or `monolith/` (built for you) by hand.
- Write every commit as a [conventional commit](#commit-messages), and fold corrections to your own branch into the commit they correct before you push (see [Fixups](#fixups-before-the-first-push)).

## Local setup

You need Git and Node.js. The Salesforce CLI (`sf`) and an org you can deploy to are optional: your pull request is validated for you.

| Step | Command | Why |
|---|---|---|
| 1. Clone with submodules | `git clone --recurse-submodules --shallow-submodules <repository-url>`<br>`cd <repository-folder>`<br>`git config submodule.recurse true` | Fetches the two upstream fflib libraries into `dependencies/`, and keeps them on the commits each branch pins when you switch or pull |
| 2. Assemble | `node build/scripts/assemble-monolith.cjs` | Builds the combined package content and runs guards the pull request runs too |
| 3. Validate (optional) | `sf project deploy validate --source-dir monolith --source-dir code-examples --test-level RunLocalTests --target-org <alias> --wait 60` | Runs the same deployment validation, with tests, as the pull request check |

The assembled tree (`monolith/`) is our `force-app/` source plus the pinned upstream fflib sources: it is what the full package is built from.

<details>
<summary>More on the setup</summary>

- A clone made without `--recurse-submodules` needs `git submodule update --init --depth 1` before step 2. The command does nothing after `--recurse-submodules`.
- After a branch moves an upstream pin, run step 2 again. When you switch between branches that pin different upstream commits, `git status` shows a submodule as modified until it is checked out at the new pin: with `submodule.recurse true` the switch does it, otherwise run `git submodule update --init --depth 1` after the switch.
- `git add dependencies/` stages a pin, so never run it by accident.
- The script deletes and rebuilds `monolith/` (gitignored, never edited by hand) and runs the guards: it prints one `::error::` line per finding and exits 1 when there is any. The guards fail a duplicate class name and a `dfflib_` class that references an `fflib_` class which has a `dfflib_` twin.
- `MONOLITH_PATH` changes the output folder (a repo-relative path that is not a source folder and that git ignores).
- There is no `package.json`, so there is no `npm run` shortcut. No formatter, lint or analyser config exists for Apex, so nothing excludes `dependencies/` or `monolith/`.
- The deployment validation enforces 75% code coverage.

</details>

## Workflow

1. Fork the repository. If you have write access to this repository, you can push your branch here instead; the steps are the same.
1. Create a branch, following the [branch naming convention](#branch-name).
1. Change source under `force-app/` and deploy, run the unit tests and validate the behaviour in your org.
1. Assemble and, if you like, validate (steps 2 and 3 of [Local setup](#local-setup)).
1. Commit your changes, following [Commit messages](#commit-messages).
1. Push the branch.
1. Open a pull request against `main`, with a title and description as in [Pull request title and description](#pull-request-title-and-description). Fill in the template.
1. Code owners are requested for review automatically (see `CODEOWNERS`), and labels are applied for you.

On a pull request from a fork, the `validate-project` check fails. That is expected: a Maintainer validates your change before it merges. If you validated it against your own org (step 3 of [Local setup](#local-setup)), say so in the description.

### Branch name

Branch names follow the syntax `feature/<YYYYMMDD>-<issue>-<description>`: today's date, the issue number (leave it out when there is none) and a short hyphenated description:
```bash
git checkout -b feature/20261113-42-add-selector-filter
```

### Commit messages

Release automation reads every commit that lands on `main`, branch commits included, so the type of each commit matters.
This repository follows the [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/#summary), which means:

- A clear subject line with [type](#types) and an optional [scope](#scope) and/or `!` breaking-change marker:
   ```
   <type>: <description>
   <type>(<scope>): <description>
   <type>!: <description>
   <type>(<scope>)!: <description>
   ```
- Optionally followed by a blank line and a body (see [Body rules](#body-rules))

#### Subject rules

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
refactor(selectors): simplify SOQL builder interface
feat(selectors)!: drop the deprecated selectSObjectsById overload
```

#### Body rules

The body is optional: explain why, wrapped at 72 characters.

```
docs(code-examples): add code-examples folder for reference

- Give contributors examples in the Room Booking context
- Cover all layers, for standard and edge use cases
```

#### Types

| Type | Use it for | Auto-applied label | Appears in release notes as |
|---|---|---|---|
| `feat` | A new functionality/feature | `enhancement` | New features |
| `fix` | A resolution for a bug | `bug` | Bug fixes |
| `docs` | Changes to documentation | `documentation` | Miscellaneous updates |
| `style` | Formatting, with no change in behaviour | `style` | Miscellaneous updates |
| `refactor` | A code change with no change in behaviour | `refactor` | Miscellaneous updates |
| `perf` | A performance improvement | `performance` | Miscellaneous updates |
| `test` | Tests only | *(none)* | Miscellaneous updates |
| `chore` | Maintenance | `chore` | Miscellaneous updates |
| `build` | Build scripts and packaging | *(none)* | Miscellaneous updates |
| `ci` | Workflows | *(none; `ci` comes from the file-based labeler)* | Miscellaneous updates |
| `revert` | Reverting an earlier commit | *(none)* | Miscellaneous updates |

The label is set based on the pull request title (see [Pull request validations](#pull-request-validations)), and the release notes group pull requests by label.

- **The type describes the change to the package.**
- **The highest type decides the version bump**: a breaking change gives a major, `feat` a minor, anything else a patch.
- **A breaking change** puts `!` right after the type and before the colon (`feat!:`, `fix!:`, `refactor!:` ...) and/or adds a `BREAKING CHANGE: <what breaks>` footer. It is listed under Breaking Changes.
- **Non-conventional commits** (`wip`, `tweak`) are ignored by release automation; squash them before pushing.

#### Scope

A scope is optional in a commit subject: a short noun in parentheses right after the type. Leave it out of pull request titles.

```
feat(selectors): add dynamic field filtering
fix(triggers): handle missing related record gracefully
```

Common scopes in this project: `triggers`, `selectors`, `services`, `domains`, `mocks`, `lwc`, `ci`, `deps`.


#### Fixups before the first push

Correct your own branch's mistakes with fixups, not `fix:` commits. A bug that only ever existed on your branch is not a fix for users:

```bash
git commit --fixup=<sha>                 # recorded as "fixup! <original subject>"
git rebase -i --autosquash origin/main   # folds it into <sha>
```

Do this before the first push. After that it needs `git push --force-with-lease` on your own branch.



### Pull request title and description

- **Title**: the commit subject format from [Commit messages](#commit-messages), with no scope. On a single-commit branch GitHub pre-fills the title from the commit subject; on a single-commit branch or a squash merge, keep the title identical to the commit subject, apart from removing the scope. The `pr-template-validation` check fails a title that does not follow the format.
- **Description**: at least 10 characters that say what changed, why, and how you tested it. Placeholder text such as `todo`, `tbd`, `wip`, `n/a`, `none` or only dashes fails the check. Fill in the template and keep its `## Description` and `## Checklist` headings: the check reads those two.

#### Pull request validations

Several checks run on pull requests to keep the code consistent.

- **`assemble-guards`** runs on every pull request. It fails when the guards find a problem; step 2 of [Local setup](#local-setup) shows the same findings locally.
- **`validate-project`** runs when a pull request changes the package source, the code examples, the upstream pins or the project configuration. It deploys the change with all local tests, which must reach 75% code coverage; step 3 of [Local setup](#local-setup) runs the same validation. On a fork it fails (see [Workflow](#workflow)).
- **`pr-template-validation`** fails a title that is not a conventional commit, and a description that is too short or placeholder text. It re-runs when you edit the title or description.
- **`pr-labels`** applies the label for the title type (the label column of the [types table](#types)), and `breaking` for a breaking change. Correct the title and the labels follow.
- **`Release readiness`** passes on every contributor pull request.