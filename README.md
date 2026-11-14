# D'fflib

[![Licence: BSD 3-Clause](https://img.shields.io/badge/licence-BSD%203--Clause-blue)](LICENSE)

> The framework that **truly enables** Apex developers and AI agents to deliver **scalable, maintainable and testable** Salesforce functionality. It extends the fflib (`apex-common`) framework with **redesigns, shortcuts, accelerators and the latest Salesforce features**, to **simplify usage and adoption** for a **better developer experience**, while **improving performance**.

fflib is the open-source Apex Enterprise Patterns library ([apex-common](https://github.com/apex-enterprise-patterns/fflib-apex-common) and [apex-mocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks)): it splits a Salesforce application into Domain, Selector, Service and Unit of Work layers. Separating concerns in Apex keeps the code scalable and maintainable.

D'fflib is an extension to fflib, focused on a strong developer experience. It equips developers with shortcuts, standardisation and more native Salesforce functionality, and is provided as an unlocked package for easy installation.

In addition to the coding enhancements, D'fflib comes with a [full documentation website](https://deloitte-engineering.github.io/dfflib), including snippets for core fflib and D'fflib extensions ([code examples](/code-examples)), and AI enablement via our [skill](), [LLMs.txt](https://deloitte-engineering.github.io/dfflib/llms.txt) and [LLMs-full.txt](https://deloitte-engineering.github.io/dfflib/llms-full.txt).

Interested in the benefits? See our [business](https://deloitte-engineering.github.io/dfflib/docs/why/business-benefits/) and [technical benefits](https://deloitte-engineering.github.io/dfflib/docs/why/technical-benefits/) pages.

## D'fflib and fflib

| | fflib | D'fflib |
|---|---|---|
| Layers | Domain, Selector, Service, Unit of Work | The same layers, extended |
| Where the code lives | Source you deploy from your own project | An unlocked package, so the framework code stays out of your repository |
| Class names | `fflib_` | `dfflib_` classes next to the `fflib_` classes |
| Setup | In code, in your `Application` class | Metadata-driven, through custom metadata types |

After alignment with the fflib AEP core team, D'fflib is provided as an extension to fflib. This also enables a gradual or partial upgrade of your code, depending on your capacity.
Existing classes can extend or call `fflib_` classes, while others update references to the `dfflib_` classes.

### Features

Each feature links to its page on the documentation website, with the reasoning, the full method list and code examples.

| Feature | What you get |
|---|---|
| [Accelerators & Utilities](https://deloitte-engineering.github.io/dfflib/docs/what/accelerators-utilities/) | **One-line mocks for every layer** with `defineMock()`. Ready-to-use input validation methods, exception types and collection utilities to filter, group and collect values from `SObject` lists. |
| [Metadata-driven application](https://deloitte-engineering.github.io/dfflib/docs/what/metadata-driven/) | **No `Application` class to write or merge.** Layer mappings live in custom metadata, so each developer adds a record instead of editing one shared class. Works with SFDX packaging and avoids org-wide compile or merge errors. |
| [Database Context](https://deloitte-engineering.github.io/dfflib/docs/what/database-context/) | **Enabling a calling class to control both sharing and FLS/CRUD** with one enum. Standardised signature for Unit of Work and Selector: `SEL_Leads.newInstance( dfflib_Database.Context.FULL )`. No more `without sharing` inner classes or `withSharing` flags. Built on user mode (API 57+). |
| [Selectors 2.0](https://deloitte-engineering.github.io/dfflib/docs/what/selectors/) | **Unit test a selector without running a query**, with built-in assertion shortcuts. Supports `Database.Cursor`, aggregates (`SUM`, `COUNT`, `HAVING`) and SOQL features such as `TYPEOF`, `DISTANCE` and `FOR UPDATE`. |
| [Unit of Work 2.0](https://deloitte-engineering.github.io/dfflib/docs/what/unit-of-work/) | **14x faster commit cycles.** Supports most `Database` operations like `SaveResults`, `DMLOptions`, `Immediate`, complex relationships, approvals and emails. Test coverage raised from 68% to 98%. |
| [Trigger Handler Framework](https://deloitte-engineering.github.io/dfflib/docs/what/trigger-framework/) | **Robust and bulkified trigger handlers.** Each handler runs `initialize()`, `process()` and `finalize()`, which keeps SOQL and DML out of loops. All handlers share one Unit of Work commit and are easy to unit test. |
| [Test Data Builder Framework](https://deloitte-engineering.github.io/dfflib/docs/what/test-factory-builder-framework/) | **Fluent, typed test data** such as `TestFactory.anAccount()`, with parent and child records linked for you. Formula and read-only fields can be set without DML. Choose `.mock()`, `.mockWithIds()` or `.save()`. A new required field means one fix, not hundreds. |
| [Unlocked package](https://deloitte-engineering.github.io/dfflib/docs/how/get-started/) | **Easy install and update**, with the ability to remove framework classes from your repository, shaving ~5 minutes off every full test run. |

## Install

D'fflib comes in two packages.

| | Full package | BYO package (bring your own fflib) |
|---|---|---|
| Includes | fflib and `dfflib_` classes | `dfflib_` only |
| Apply when | The org has no fflib yet, or you prefer less maintenance overhead | You want to control the fflib version |

- For a full guide, check the [Getting Started page](https://deloitte-engineering.github.io/dfflib/docs/how/get-started/), or the migration steps in each layer's How article.
- See the [Releases](../../releases) page for updates, release notes and install links. Follow the **Sandbox** or **Production** link of the package you picked, or run:
    ```bash
    sf package install --package <04t id of the package version> --target-org <alias> --wait 20
    ```

## Support

- Raise questions, bugs and requests in this repository's [Issues](../../issues).
- Contributions are highly appreciated; see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
- Check our [How articles](https://deloitte-engineering.github.io/dfflib/docs/how/overview/) for detailed examples for core and edge cases, and an overview of how the layers are set up to interact.
- Unsure whether you've applied (D')fflib effectively, or want your team trained?
    See our [Support page](https://deloitte-engineering.github.io/dfflib/docs/how/support/).

## Licence

D'fflib is released under the [BSD 3-Clause Licence](LICENSE).
It was originally initiated by Deloitte; usage is free and has no dependency on Deloitte.
