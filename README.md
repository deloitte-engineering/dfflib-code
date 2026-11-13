# D'fflib

[![License: BSD 3-Clause](https://img.shields.io/badge/license-BSD%203--Clause-blue)](LICENSE)

fflib is the open-source Apex Enterprise Patterns library ([apex-common](https://github.com/apex-enterprise-patterns/fflib-apex-common) and [apex-mocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks)): it splits an application into Domain, Selector, Service and Unit of Work layers. D'fflib is built on fflib and adds developer-efficiency features on top of those layers, installed as an unlocked package.

## D'fflib and fflib

| | fflib | D'fflib |
|---|---|---|
| Layers | Domain, Selector, Service, Unit of Work | The same layers, extended |
| Where the code lives | Source you deploy from your own project | An unlocked package, so the framework code stays out of your repository |
| Class names | `fflib_` | `dfflib_` classes next to the `fflib_` classes |
| Setup | In code, in your `Application` class | Metadata-driven, through custom metadata types |

To get the D'fflib behaviour, extend or call the `dfflib_` class; to stay on upstream, use the `fflib_` class. Keep one class chain on one side: a `dfflib_` class does not know about an `fflib_` subclass of its twin, and the reverse.

## Install

D'fflib comes as two packages. Pick one:

| | Monolith package | BYO package (bring your own fflib) |
|---|---|---|
| Carries | fflib and the `dfflib_` classes | The `dfflib_` classes only |
| Use it when | The org has no fflib yet | The org already has fflib, deployed from your own project |

**Never install both in one org.** The monolith package already holds every `dfflib_` class, so the BYO package would collide with it.

Every version, with its release notes and install links, is on the [Releases](../../releases) page. Follow the **Sandbox** or **Production** link of the package you picked, or run:

```bash
sf package install --package <04t id of the package version> --target-org <alias> --wait 20
```

For the BYO package, deploy fflib to the org first, at the commits the release notes list for that version, and install in a sandbox that holds your fflib before you install in production.

## Support

Open an issue in this repository's [Issues](../../issues) for questions, bugs and requests. To change D'fflib itself, see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

D'fflib is released under the [BSD 3-Clause License](LICENSE).
