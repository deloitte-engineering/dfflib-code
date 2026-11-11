# Contributing to D'fflib

Thank you for contributing to D'fflib. This guide takes you from a clone to a merged pull request. To install the packages instead, see the [README](README.md). Ask questions, report bugs and propose changes in this repository's Issues.

## Prerequisites

- Git
- Node.js: runs the assemble script (`build/scripts/assemble-monolith.cjs`)
- Salesforce CLI (`sf`) and a Salesforce org you can deploy to: only if you want to validate a change yourself. The pull request check validates it for you (see [Validate your change](#validate-your-change)).

## Setup

1. Clone the repository:
   ```bash
   git clone --recurse-submodules --shallow-submodules <repository-url>
   cd <repository-folder>
   git config submodule.recurse true
   ```

   `--recurse-submodules` fetches the two upstream fflib libraries in `dependencies/`. `submodule.recurse true` makes `git checkout`, `git switch` and `git pull` move the submodules to the commits the branch pins. A clone made without these flags needs step 2.

2. Fetch the pinned upstream fflib libraries (submodules in `dependencies/`) and build the Assembled tree (`monolith/`):
   ```bash
   git submodule update --init --depth 1
   node build/scripts/assemble-monolith.cjs
   ```
   Run both once after cloning (the first does nothing after `--recurse-submodules`), and again after a branch moves an Upstream pin. When you switch between branches that pin different upstream commits, `git status` shows a submodule as modified until it is checked out at the new pin: with `submodule.recurse true` the switch does it, otherwise run `git submodule update --init --depth 1` after the switch. `git add dependencies/` stages a pin, so never run it by accident. The script deletes and rebuilds `monolith/` (gitignored, never edited by hand) and runs the guards: it prints one `::error::` line per finding and exits 1 when there is any. `MONOLITH_PATH` changes the output folder (a repo-relative path that is not a source folder and that git ignores). There is no `package.json`, so there is no `npm run` shortcut. No formatter, lint or analyzer config exists for Apex, so nothing excludes `dependencies/` or `monolith/`.

## Workflow

### Create a branch

```bash
git checkout -b feature/your-feature-name
```

Any branch name works. Change source under `force-app/`; never edit `dependencies/` or `monolith/` by hand.

### Validate your change

Assemble first (`node build/scripts/assemble-monolith.cjs`), then validate the Assembled tree against an org you own. This is the command the `validate-project` workflow runs:

```bash
sf project deploy validate --source-dir monolith --test-level RunLocalTests --target-org <alias> --wait 60
```

The deployment validation enforces 75% code coverage. The workflow runs on a pull request that changes `force-app/**`, `dependencies/**`, `.gitmodules`, `sfdx-project.json` or the assemble scripts.

### Open a pull request

- Target the `main` branch.
- Give it a title in the Conventional Commits format (below) and a real description.
- Make sure every check passes. The code owners are requested for review automatically (see `CODEOWNERS`).
- Labels are applied for you by the `pr-labels` workflow.

#### From a fork

Fork the repository, push a branch to your fork and open the pull request against `main`. GitHub does not pass repository secrets to workflows that run for a fork, so `validate-project` cannot log in to its org for your pull request: validate your change yourself with the command above, and say so in the description. The release workflows refuse a pull request from a fork.

#### PR title

Every pull request title must follow the [Conventional Commits](https://www.conventionalcommits.org/) format. The `pr-template-validation` check fails a pull request whose title does not.

> **Where the title comes from:** GitHub pre-fills the PR title from your commit subject line when the branch has a single commit. Write that first line as a conventional-commit subject of at most ~72 characters and put extra detail in the commit body and the PR description. For multi-commit branches, set the title manually.

```
<type>: <description>
<type>(<scope>): <description>
<type>!: <description>
<type>(<scope>)!: <description>
```

The `!` marks a breaking change and goes right before the colon.

Examples:

```
feat: add opportunity scoring algorithm
fix(triggers): resolve null pointer in AccountTriggerHandler
docs: update the README install steps
refactor(selectors): simplify SOQL builder interface
feat(selectors)!: drop the deprecated selectSObjectsById overload
```

##### Types, labels and release notes

| Type       | Auto-applied label | Appears in release notes as |
|------------|--------------------|-----------------------------|
| `feat`     | `enhancement`      | New features                |
| `fix`      | `bug`              | Bug fixes                   |
| `docs`     | *(none)*           | Miscellaneous updates       |
| `style`    | `style`            | Miscellaneous updates       |
| `refactor` | `refactor`         | Miscellaneous updates       |
| `perf`     | `performance`      | Miscellaneous updates       |
| `test`     | *(none)*           | Miscellaneous updates       |
| `chore`    | `chore`            | Miscellaneous updates       |
| `build`    | *(none)*           | Miscellaneous updates       |
| `ci`       | *(none; `ci` comes from the file-based labeler)* | Miscellaneous updates |
| `revert`   | *(none)*           | Miscellaneous updates       |

A pull request labelled `breaking` is listed under Breaking Changes. The categories come from `.github/release.yml`. The `breaking` label is applied automatically when the title has `!` before the colon or the description has a line starting with `BREAKING CHANGE:`, and removed when neither is left.

The `pr-labels` workflow reads the title type through `build/scripts/pr-title.cjs`, the one list of title types. It removes any stale conventional label and applies the mapped one. An invalid title leaves labels untouched; `pr-template-validation` is the check that blocks it. If you edit the title several times in a row, the last state wins.

##### Scope (optional)

A scope is a short noun in parentheses right after the type:

```
feat(selectors): add dynamic field filtering
fix(triggers): handle missing related record gracefully
```

Common scopes in this project: `triggers`, `selectors`, `services`, `domains`, `mocks`, `lwc`, `ci`, `deps`.

##### Title rules

1. **Lowercase type**: `feat:` is valid, `Feat:` and `FEAT:` are not
2. **Colon and space required**: `feat: description` is valid, `feat:description` and `feat - description` are not
3. **Description required**: the title must not end after the colon
4. **Imperative mood**: write "add feature", not "added feature" or "adds feature"
5. **No period at the end**
6. **Breaking marker only before the colon**: `feat!: ...` and `fix(uow)!: ...` are valid, `!feat: ...`, `feat!(uow): ...` and `feat:! ...` are not

#### PR description

- At least **10 characters**.
- Empty or placeholder descriptions (`todo`, `tbd`, `wip`, `-`) fail the check.
- Say what changed, why, and any testing or deployment notes for reviewers.

### Commit messages

Branch commits use the same format as PR titles: lowercase type, optional scope, imperative description, no trailing period, subject of at most ~72 characters. Release automation reads every commit that lands on `main`, branch commits included, so the type matters:

- **The type describes the change to the package.** `feat` is a new capability for package users; `fix` is a bug users could hit. Supporting steps on the same branch use `test`, `refactor`, `docs`, `chore` or `ci`.
- **The highest type decides the version bump**: a breaking change gives a major, `feat` a minor, anything else a patch. One stray `feat:` in a bug-fix branch makes a minor release.
- **Correct your own branch's mistakes with fixups, not `fix:` commits.** A bug that only ever existed on your branch is not a fix for users:

  ```bash
  git commit --fixup=<sha>                 # recorded as "fixup! <original subject>"
  git rebase -i --autosquash origin/main   # folds it into <sha>
  ```

  Do this before the first push. After that it needs `git push --force-with-lease` on your own branch.
- **An upstream pin bump** (`dependencies/`) is `fix(deps):`; see [Bump an Upstream pin](#bump-an-upstream-pin).
- **Breaking changes** use `feat!:` (or `fix!:`, `refactor!:` ...) and/or a `BREAKING CHANGE: <what breaks>` footer.
- **Non-conventional commits** (`wip`, `tweak`) are ignored by release automation; squash them before pushing.
- **The body is optional**: explain why, wrapped at 72 characters.

```
feat(selectors): add dynamic field filtering

Let callers pass a field set at runtime instead of overriding
getSObjectFieldList().
```

### Merge method

A pull request is merged with a **merge commit**, so release automation reads your branch commits. Squash is the exception. GitHub names a squash commit after the single commit's subject, or after the PR title when the branch has several commits, so keep the PR title and the first commit subject identical. Do not rebase-merge.

## Bump an Upstream pin

A pin moves only through a reviewed pull request from a feature branch, never in a pipeline. The bump is the one change in the pull request:

```bash
git checkout -b feature/bump-fflib-apex-common
git submodule update --remote --depth 1 dependencies/fflib-apex-common   # or dependencies/fflib-apex-mocks
node build/scripts/assemble-monolith.cjs                                  # the guards must pass
git add dependencies/fflib-apex-common
git commit -m "fix(deps): bump fflib-apex-common to <short SHA>"
```

Type the commit `fix(deps):`: `fix` is a releasing type and `dependencies/` is not in `exclude-paths` of `release-please-config.json`, so a bump opens a release PR on its own; the human gates stay (beta build request, merge). The scope is a convention: nothing enforces it. The pull request runs the `assemble-guards` check (it runs on every pull request) and `validate-project` (it validates the Assembled tree because `dependencies/**` changed), gets the `dependencies` label, and asks the code owners of `dependencies/` and `.gitmodules` for review. That review is the control on what a bump pulls in from upstream.

### When a bump fails

A bump fails when an assemble guard reports a duplicate name, a `dfflib_` class that references an `fflib_` class with a `dfflib_` twin, or an upstream class that `force-app/` uses and upstream renamed or removed; or when `validate-project`, a beta build or a deploy fails after it merged.

1. Find the last good pin: `git log --oneline -- dependencies/fflib-apex-common`, then `git ls-tree <last good commit> dependencies/fflib-apex-common` prints the upstream SHA it pinned.
2. Pin back in a new branch and a new pull request:
   ```bash
   git -C dependencies/fflib-apex-common fetch --depth 1 origin <good upstream SHA>
   git -C dependencies/fflib-apex-common checkout <good upstream SHA>
   node build/scripts/assemble-monolith.cjs
   git add dependencies/fflib-apex-common
   git commit -m "fix(deps): pin fflib-apex-common back to <short SHA>"
   ```
3. Never edit `dependencies/` by hand and never delete a submodule: the guards fail any tracked entry there other than the two pointers. A change that makes the code work with a newer pin goes in `force-app/`, in its own pull request.
4. The pin-back changes the content roots, so a beta build recorded for the failed pin goes stale and the release PR is not ready until a Maintainer asks for a new beta build (see [Maintainers](#maintainers)). While a Release freeze is on, the pin-back cannot merge until the release PR merges or closes.

## Code style

- Match the surrounding code.
- Give new classes in `force-app/` the `dfflib_` prefix. The assemble guards fail a duplicate class name and a `dfflib_` class that references an `fflib_` class which has a `dfflib_` twin.
- Include unit tests for new functionality.
- Update the documentation when behaviour changes.

## Maintainers

A Maintainer has the `maintain` or `admin` role on the repository. Release mechanics:

- **Release PR.** Release automation (release-please) opens a release PR when a releasing commit lands on `main`.
- **Beta build.** Only a Maintainer can start one: add the `release: build-beta` label to the release PR. The label is removed on every request, so adding it again asks again.
- **Release freeze.** From a beta build until its release PR merges, changes to `force-app/` and `dependencies/` cannot merge.
- **Release notes override.** The generated notes can be replaced by editing the override comment on the release PR; it counts only when its last editor is a Maintainer.
- **Fork pull requests.** Validate the change before merging, because `validate-project` cannot log in for a fork (see [From a fork](#from-a-fork)).

## Questions

Open an issue in this repository.
