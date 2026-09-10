# Contributing to `{{VENDOR}}/{{PACKAGE}}`

{{DESCRIPTION}}

This bundle is a dependency of other projects: its public surface is a promise,
and its version number is part of its interface. A pull request that adds a case
nobody has hit yet is a harder sell than one that fixes a case you did hit — say
which one yours is.

Read [README.md](../README.md) first; it documents the configuration and the
contracts. This file covers the workflow.

<!-- Bundle author: once this bundle has a subject of its own, add its house
     rules to the section below — the ones a pull request gets refused over.
     The generic ones are already there; yours are the interesting ones. -->

## Before you open anything

* **Bug** → open an [issue](https://github.com/{{VENDOR}}/{{PACKAGE}}/issues/new/choose)
  with the bundle version, the Symfony version, and the shortest failing test
  you can write. A failing test is worth more than a description, and it is what
  a fix will be built on.
* **New feature, new configuration key, new contract method** → open an issue
  first. Adding to the public surface is cheaper to discuss before the code than
  after.
* **Security problem** → do not open an issue. Follow [SECURITY.md](SECURITY.md).

## Setting up

```bash
git clone https://github.com/{{VENDOR}}/{{PACKAGE}}.git
cd {{PACKAGE}}
composer install
```

You need PHP **{{PHP_CONSTRAINT}}** and Composer 2. There is nothing to boot: the
bundle is exercised through its test kernel, which the suite builds for you.

## The quality gate

```bash
composer qa
```

That is the whole contract, and it runs the four checks in the order the CI runs
them:

| Step | What it is | Fix it with |
| --- | --- | --- |
| `cs-check` | php-cs-fixer, `--dry-run --diff` | `composer cs` |
| `rector-check` | Rector, `--dry-run` | `composer rector` |
| `phpstan` | PHPStan at **`level: max`** | by hand — a baseline entry is a last resort, not a shortcut |
| `test` | PHPUnit | by hand |

`composer qa` green is the minimum for a pull request, not the goal. The suite is
configured to fail on deprecations, notices, warnings and risky tests, so a test
that passes while emitting a deprecation is a failing test here.

## What the CI checks that your machine does not

[`.github/workflows/ci.yml`](workflows/ci.yml) runs three jobs, and two of them
catch what a local run cannot:

* **The dependency matrix** — the test suite runs on both `highest` **and**
  `lowest` dependencies. The `lowest` set is not a formality: it catches typed
  parameters incompatible with older releases of a dependency, and vendor
  deprecations, both of which are green locally. If you widen a constraint in
  `composer.json`, that job is the one that says whether you may.
* **`composer validate --strict`** — a malformed or inconsistent `composer.json`
  fails the build.
* `SYMFONY_REQUIRE` pins the whole `symfony/*` set to one minor, so the matrix
  stays honest instead of letting Composer mix components from several branches.

## Semantic versioning is a promise here

* **patch** — a fix that changes no signature and no configuration key;
* **minor** — something added that existing code keeps working without;
* **major** — anything a dependent application must change code for: a removed
  or renamed configuration key, a new method on a contract interface, a narrowed
  parameter type, a changed default.

Adding a method to an interface the application implements is a **breaking
change**, even though PHP will not tell you so until someone upgrades. Say so in
the pull request when yours does.

## House rules

1. **The bundle carries what every application would otherwise rewrite; anything
   specific to one domain stays in the application.** That line is where most
   review comments land. When in doubt, say in the pull request why the code
   cannot live in the project that needs it.

2. **An optional dependency is registered from the extension, guarded by
   `class_exists()` — never by an attribute on the class.** An `#[AsDecorator]`
   or `#[AsDoctrineListener]` on a vendor class is only honoured when the
   application autoconfigures `vendor/`, which it should not, and it makes the
   class unloadable the moment the package is absent.

3. **A service that needs another *service* to exist is checked in a compiler
   pass, not in the extension.** Extensions run before the other bundles have
   configured anything, so `$container->has('some.service')` is always false
   there.

4. **A new runtime dependency is a discussion, not a commit.** Everything in
   `require` is imposed on every application installing this bundle. Prefer
   `suggest` plus a graceful degradation.

5. **`level: max`, and a baseline entry is a last resort.** Silencing PHPStan
   moves the cost to whoever upgrades.

6. **Nothing sensitive reaches a log or an exception message** — no password, no
   token, no key material, no personal data. An exception message is read by
   whoever can see a stack trace.

7. **No route without an access decision.** Every controller action this bundle
   ships carries an explicit decision — `#[IsGranted(...)]` or
   `denyAccessUnlessGranted(...)` — including the deliberately public ones.
   Silence does not authorise, it forgets to refuse.

## Tests

Tests live in `Tests/`, mirroring the source tree.
`Tests/Fixtures/TestKernel.php` boots a real container rather than a mock, and
`Tests/Functional/` uses it — so a service that no longer compiles fails the
suite instead of failing an application on install. When you add a configuration
key, wire it in that kernel too.

A bug fix comes with the test that fails without it. That is not a formality: it
is how a fix survives the next refactoring.

## One trap that is not yours

Any later `composer require` or `composer update` **in this repository** re-runs
the Flex recipes, and they write into two tracked files: `phpunit.xml.dist`
(framework-bundle adds `APP_ENV=dev`, doctrine-bundle a PostgreSQL
`DATABASE_URL`) and `.gitignore`. So after adding a dependency, read `git status`
before `git add` — a `DATABASE_URL` pointing at a database the test kernel does
not use is the kind of line someone reads and believes.

## Pull requests

* One subject per pull request.
* Fill in the [template](pull_request_template.md), including the `composer qa`
  result — a pull request that does not say whether the gate is green cannot be
  reviewed.
* Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  `fix: …`, `feat: …`, `docs: …`, `chore: …`, and `feat!:` / `fix!:` for a
  breaking change.
* Update the README in the same pull request when you add or change a
  configuration key, a contract or a public service.
* Rebase on `master` rather than merging it back in.

## Code of conduct

Participation is covered by our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Contributions are accepted under the [MIT license](../LICENSE) that covers this
repository.
