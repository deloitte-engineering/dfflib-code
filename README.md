# D'fflib

![License: BSD 3-Clause](https://img.shields.io/badge/license-BSD%203--Clause-blue)

D'fflib is an extended version of the open-source fflib Apex libraries ([apex-common](https://github.com/apex-enterprise-patterns/fflib-apex-common) and [apex-mocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks)), maintained by Deloitte. It keeps fflib's layered structure and adds developer-efficiency features: metadata-driven setup, extended Unit of Work and Selectors, a trigger framework, a test data builder and accelerators. It installs as an unlocked package, so the framework code stays out of your repository.

D'fflib ships as two unlocked packages, built from one release: the monolith package and the BYO (extensions) package, called BYO from here on. Pick one.

## Choose a package

| | Monolith package | BYO package (bring your own fflib) |
|---|---|---|
| Carries | The upstream fflib libraries (`fflib_` classes) and our `dfflib_` classes | Our `dfflib_` classes only |
| Package type | Unlocked | Org-dependent unlocked |
| Needs fflib in the org | No, it brings its own | Yes, you provide it |
| Use it when | The org has no fflib yet, or you want one package to own it | The org already has fflib (your own copy, deployed from source) |

**The two packages are alternatives. Never install both in one org**: the monolith package already holds every `dfflib_` class, so the BYO package would collide with it.

A release gives each package one package version, and both share the same `X.Y.Z`. Their `BUILD` numbers can differ.

### Install the monolith package

1. Open the GitHub Release you want and follow its monolith **Sandbox Install** or **Production Install** link, or run:
   ```bash
   sf package install --package <04t id of the monolith package version> --target-org <alias> --wait 20
   ```
2. Nothing else is needed: the package holds the `fflib_` and `dfflib_` classes.

### Install the BYO package

1. Put fflib in the org first, as plain source from your own project (for example the `fflib-apex-common` and `fflib-apex-mocks` repositories, deployed through your project). **Your project must resolve fflib itself**: an org-dependent package cannot depend on another package, and it is not checked at build time. The install is the check, and it fails when a class the BYO package uses is missing.
2. Deploy the same upstream commits the release was built from. The release notes list one pinned commit per upstream repository (the Notes cell of the unlocked package lists them after "Incl."); the Upstream pins are also the two submodule pointers (`dependencies/`) at the release tag.
3. Install the BYO package with its link on the GitHub Release, or:
   ```bash
   sf package install --package <04t id of the BYO package version> --target-org <alias> --wait 20
   ```

An org-dependent package is not "build once, install anywhere": install it first in a sandbox that holds your fflib, then in production. Salesforce does not calculate its code coverage, so the coverage check is waived for this package only.

## Mixing `fflib_` and `dfflib_` classes

- A `dfflib_` class refers to `dfflib_` classes. It refers to an `fflib_` class only when no `dfflib_` twin exists (for example `fflib_Application`, `fflib_SObjectDomain`, `fflib_SObjectSelector`, `fflib_SObjectUnitOfWork` and `fflib_QueryFactory` all have one). The assemble guards fail a change that breaks this rule.
- Your own code picks the side per class. To extend or call the D'fflib behaviour, extend or call the `dfflib_` class; to stay on upstream, use the `fflib_` class. Do not make one class chain mix the two: a `dfflib_` class does not know about an `fflib_` subclass of its twin, and the reverse.
- In an org with only the BYO package, `fflib_` classes come from your own copy of fflib; in an org with the monolith package they come from the package.

## Versions and release notes

Every version, with its release notes and install links, is on the [Releases](../../releases) page.

## Support

Open an issue in this repository's [Issues](../../issues) for questions, bugs and requests.

## Contributing

Setup, the submodules, the assemble step, bumping an upstream pin and what to do when a bump fails are in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

D'fflib is released under the [BSD 3-Clause License](LICENSE).
