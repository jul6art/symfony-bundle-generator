# Contributing

Thanks for taking the time. This repository generates a Symfony bundle that is
ready to pass its own CI on the first commit. The skeleton of a bundle is
trivial — a class, an extension, a configuration tree; what this generator
actually delivers is the **harness around it**, and that is what you are
contributing to.

Read [README.md](../README.md) first: it documents the bricks, the placeholders,
the two rules the templates encode, and the traps already paid for. This file
covers the workflow.

## The standard every change is measured against

> `composer qa` passes on a freshly generated bundle. If it ever does not, that
> is the generator's bug, not yours.

That sentence is from the README, and it is the acceptance criterion for a pull
request here. A template edit that leaves a generated bundle red — coding
standards, Rector, PHPStan at `level: max`, PHPUnit, `composer validate
--strict` — is not finished, however correct it looks in the template.

## Before you open anything

* **Bug** → open an
  [issue](https://github.com/jul6art/symfony-bundle-generator/issues/new/choose)
  with the `./bin/new-bundle` command line you ran. The generator is
  deterministic, so a command line plus its output is usually the whole report.
* **A new brick, or a new dependency in an existing one** → open an issue first.
  A brick is a maintenance commitment, and a dependency added to a template
  lands in every bundle generated afterwards.
* **A security problem** → do not open an issue. Follow
  [SECURITY.md](SECURITY.md).

## Working on a change

```bash
git clone https://github.com/jul6art/symfony-bundle-generator.git
cd symfony-bundle-generator
./bin/new-bundle probe --with=orm --dry-run   # prints everything, writes nothing
```

You need PHP **^8.5**, Composer 2, the [Symfony CLI](https://symfony.com/download)
and Git.

## Validating a change

There is no CI on this repository — the CI lives in what it *writes*. So
validation means generating a bundle and running the harness inside it:

```bash
./bin/new-bundle probe --with=orm --dir=/tmp/probe-bundle
cd /tmp/probe-bundle && composer install && composer qa
```

Which combinations to generate depends on where you edited:

| You touched | Generate |
| --- | --- |
| `common/overlay/` | at least a bare bundle **and** one with every brick |
| `bricks/<name>/` | that brick alone, and that brick combined with `twig` or `orm` |
| `bin/new-bundle` | a bare bundle, one with every brick, one `--dry-run`, one `--vendor=` / `--namespace=` override |
| a template's CI workflow | generate, push the bundle to a scratch repository, and let the workflow actually run |

Bricks are **cumulative, not exclusive**, so the combinations are where the bugs
are: a `form` + `twig` bundle and an `orm` + `security` bundle exercise
different halves of the `TestKernel`.

Say in the pull request which combinations you generated and what `composer qa`
answered for each.

## Ground rules

1. **Nothing goes into `require`.** A brick adds *development* dependencies and
   switches on the matching part of the `TestKernel`. What a bundle truly
   requires can only be decided once you know what is optional, and the answer
   is almost never "everything it uses" — so a brick that uses
   `symfony/console` produces `suggest` plus a conditional registration, never a
   hard requirement forced on every consumer.

2. **An optional dependency is registered from the extension, guarded by
   `class_exists()` — never by an attribute on the class.** An `#[AsDecorator]`
   or `#[AsDoctrineListener]` on a vendor class is only honoured when the
   application autoconfigures `vendor/`, which it should not, and it makes the
   class unloadable the moment the package is absent.

3. **A service that needs another *service* to exist is checked in a compiler
   pass, not in the extension.** Extensions run before the other bundles have
   configured anything, so `$container->has('some.service')` is always false
   there. `PurgeCommandPass` in `core-bundle` and `MercureHubPass` in
   `push-bundle` exist for exactly this reason, and a template that gets this
   wrong reproduces the bug in every bundle generated afterwards.

4. **The generated harness keeps its teeth.** `level: max` with no baseline,
   PHPUnit failing on deprecations, notices, warnings and risky tests, and the
   dependency matrix running `highest` **and** `lowest`. Every one of those
   caught a real problem in the bundles this ecosystem ships — several invisible
   to a local run. Loosening one is a change to argue for explicitly, not a
   side effect of another edit.

5. **Every guard keeps the comment that explains why it exists.** The templates
   are read by whoever generated the bundle, months later. A guard nobody
   understands is a guard someone deletes.

6. **A template is data, not code.** Adding a brick means adding a directory —
   `brick.conf` and its package lists — not touching `bin/new-bundle`. If a
   brick cannot be expressed that way, say so in the issue: that is a design
   discussion about the generator.

7. **Placeholders stay documented.** A new placeholder goes in the README's
   table in the same pull request, or the next person will not know it exists.

## The trap the generator cannot protect you from

Any later `composer require` or `composer update` **inside a generated bundle**
re-runs the Flex recipes, and they write into two files the bundle tracks:
`phpunit.xml.dist` (framework-bundle adds `APP_ENV=dev`, doctrine-bundle a
PostgreSQL `DATABASE_URL`) and `.gitignore`. The generator restores both at
generation time; it cannot restore them six weeks later.

So when you validate a change by adding a dependency to a generated bundle, read
`git status` before `git add`. This has already happened once in
`dataflow-bundle`, with the warning written in that very bundle's `.gitignore`.

## Pull requests

* One subject per pull request. A new brick and a fix to `common/overlay/` are
  two pull requests.
* Fill in the [template](pull_request_template.md), including which combinations
  you generated — a pull request that does not say cannot be reviewed.
* Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  — `fix: …`, `feat: …`, `docs: …`, `chore: …`, and `feat!:` for a change that
  alters what existing bricks generate. This repository's history is written in
  French; French and English are both fine, and the templates, comments and
  documentation stay in English.
* Update the README in the same pull request when you add a brick, an option or
  a placeholder.
* Rebase on `master` rather than merging it back in.

## Code of conduct

Participation is covered by our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Contributions are accepted under the [MIT license](../LICENSE) that covers this
repository.
