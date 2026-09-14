<p align="center">
    <a href="https://devinthehood.com"><img src="https://github.com/jul6art/symfony-skeleton-generator/blob/master/public/img/logo.png?raw=true" alt="logo dev in the hood" width="400"></a>
</p>

<p align="left">
    <a href="https://github.com/jul6art/symfony-bundle-generator/actions"><img src="https://img.shields.io/badge/php-8.5-777bb3.svg" alt="PHP 8.5"></a>
    <a href="https://github.com/jul6art/symfony-bundle-generator"><img src="https://img.shields.io/badge/symfony-7.4%20%7C%208.x-000000.svg" alt="Symfony 7.4 | 8.x"></a>
</p>

# In-house Symfony bundle generator

Generates a Symfony bundle that is ready to pass its own CI on the first commit.

The skeleton of a bundle is trivial — a class, an extension, a configuration tree. Writing it by
hand takes ten minutes. What takes longer, and what this generator actually delivers, is the
**harness around it**:

- `composer qa` — coding standards, Rector, PHPStan at **level max**, PHPUnit, in the order the CI
  runs them;
- a GitHub Actions workflow with **two dependency sets**, highest and lowest;
- a `TestKernel` that boots a real container, with Doctrine on in-memory SQLite or a security
  firewall when the bundle needs them;
- a PHPUnit configuration that fails on deprecations, notices, warnings and risky tests — and
  ignores the ones a dependency triggers inside its own code;
- and, throughout, the comments explaining *why* each guard exists.

That list is not a wish. Every item on it caught a real problem in the four bundles this
ecosystem already ships, and several of those problems were invisible to a local test run:

| What caught it | What it caught |
| --- | --- |
| `lowest deps` | a typed parameter incompatible with `psr/log` 1.x — a **fatal**, green locally on psr/log 3 |
| `lowest deps` | deprecations from vendor internals, three times, each on a different bundle |
| `rector-check` | a null comparison the coding-standards job rejected while `php-cs-fixer` was happy |
| `level: max` | a `mixed` reaching a Doctrine `PathExpression`, and a dozen more like it |

A bundle generated without that harness starts its life with the same problems and no way to see
them.

## Usage

```shell
./bin/new-bundle api --with=orm
./bin/new-bundle ui  --with=form,twig --description="Symfony UI bundle"
./bin/new-bundle acl --with=security  --dry-run
```

The name is the *subject* of the bundle, with no suffix: `api` produces the directory
`api-bundle`, the package `jul6art/api-bundle`, the namespace `Jul6Art\ApiBundle`, the extension
alias `api`, and the classes `ApiBundle` / `ApiExtension`.

| Option | |
| --- | --- |
| `--with=a,b,c` | optional bricks, see below |
| `--vendor=NAME` | package vendor (default `jul6art`) |
| `--namespace=NS` | root namespace, when it cannot be derived |
| `--dir=PATH` | target directory (default `../BUNDLES/<name>-bundle`) |
| `--description=TEXT` | package description, also the README title |
| `--dry-run` | print what would happen, write nothing |

## Bricks

```
console      commands — and a reminder that a scheduled one takes a lock
form         form types, type extensions, transformers
orm          Doctrine entities, listeners, repositories, plus the SQLite harness
security     voters, actor resolution, headers — enables the test firewall
twig         extensions, functions, a form theme
```

They are **cumulative, not exclusive**: a form bundle wants `form` *and* `twig`, an API bundle
wants `orm`. Each brick adds development dependencies and switches on the matching part of the
`TestKernel`; nothing is added to `require`.

That last point is deliberate. **What a bundle truly requires can only be decided once you know
what is optional**, and the answer is almost never "everything it uses". A brick that needs
`symfony/console` belongs in `suggest` plus a conditional service registration — not in `require`,
where it would force the package on every consumer for a feature most will not use.

## What you get

```
api-bundle/
├── .github/
│   ├── workflows/ci.yml         tests × {highest, lowest}, phpstan, cs + rector
│   ├── CONTRIBUTING.md          the quality gate, the rules below, the Flex trap
│   ├── SECURITY.md              private reporting; the scope is yours to narrow
│   ├── CODE_OF_CONDUCT.md       Contributor Covenant 2.1
│   ├── ISSUE_TEMPLATE/          bug report, feature request, config
│   └── pull_request_template.md
├── .php-cs-fixer.dist.php       @Symfony + @PHP85Migration, risky allowed
├── phpstan.dist.neon            level max, no baseline
├── rector.php                   php sets read from the composer constraint
├── phpunit.xml*                 fails on deprecations; ignores indirect ones
├── ApiBundle.php
├── DependencyInjection/
│   ├── ApiExtension.php         where conditional registration goes
│   └── Configuration.php
├── Resources/config/services.yaml
└── Tests/
    ├── bootstrap.php            wipes the compiled containers of the previous run
    ├── DependencyInjection/ConfigurationTest.php
    ├── Fixtures/TestKernel.php  ORM and security on demand
    └── Functional/
        ├── AbstractFunctionalTestCase.php
        └── ContainerTest.php    the bundle boots, and can be switched off
```

`composer qa` passes on a freshly generated bundle. If it ever does not, that is the generator's
bug, not yours.

A generated bundle also answers GitHub's community standards checklist on its first commit —
description aside, which lives in the repository settings rather than in a file. Two of those
files carry an `<!-- Bundle author: … -->` note where a generic template is not good enough:
the **house rules** in `CONTRIBUTING.md`, which should end up naming what a pull request gets
refused over in *this* bundle, and the **scope** in `SECURITY.md`, which should name what is
actually dangerous about it — the decision it takes, the input it parses, the output it renders,
the query it builds. A security policy that names the real attack surface gets useful reports; a
generic one gets none.

`SECURITY.md` links to GitHub's private vulnerability reporting, which has to be switched on per
repository before that link works for anyone outside it:

```shell
gh api -X PUT repos/jul6art/api-bundle/private-vulnerability-reporting
```

## The two rules the templates encode

**A brick whose dependency is optional is registered from the extension, guarded by
`class_exists()` — never by an attribute on the class.** An `#[AsDecorator]` or
`#[AsDoctrineListener]` on a vendor class is only honoured when the application autoconfigures
`vendor/`, which it should not, and it makes the class unloadable the moment the package is
absent.

**A service that needs another *service* to exist is checked in a compiler pass, not in the
extension.** Extensions run before the other bundles have configured anything, so
`$container->has('some.service')` is always false there. Both `PurgeCommandPass` in `core-bundle`
and `MercureHubPass` in `push-bundle` exist for exactly this reason.

## The trap after generation

⚠️ **Any later `composer require` or `composer update` inside the bundle re-runs the Flex recipes**,
and they write into two files this repository tracks: `phpunit.xml.dist` — where framework-bundle
adds `<env name="APP_ENV" value="dev"/>` and doctrine-bundle a PostgreSQL `DATABASE_URL` — and
`.gitignore`. The generator restores both at generation time; it cannot restore them six weeks
later.

So after adding a dependency to a bundle, read `git status` before `git add`. The untracked
deposits are ignored, the two tracked ones are not, and a `DATABASE_URL` pointing at a database the
test kernel does not use is the kind of line someone reads and believes.

This happened in `dataflow-bundle` on 2026-09-09, with the warning already written in the
`.gitignore` of that very bundle.

## Writing the bundle afterwards

In this order, and the order matters:

1. **the test**, against the real container;
2. **the brick**;
3. **the README section that says how to use it** — not that it exists.

A line in a table stating that a class is available has never helped anyone. For a parent class,
show the contract: the methods to implement, one complete example, what the class gives back. For
anything driven by an attribute, four things are needed, because an attribute does not say what it
triggers: the annotation in situ, **what executes it**, what to wire on the application side, and
**the trap** — what is irreversible, what must be measured first, what silently does nothing when
an optional package is missing.

## Adding a brick

```
bricks/<name>/brick.conf          DESCRIPTION="one line, shown in --help"
bricks/<name>/packages-dev.txt    one package per line, # comments allowed
bricks/<name>/overlay/            optional files copied into the bundle
```

To make part of a template conditional on a brick, wrap it in markers:

```php
// {{#orm}}
if ($this->withOrm) {
    yield new DoctrineBundle();
}
// {{/orm}}
```

Brick selected, the markers go away; brick absent, the whole block does. This is why the generated
`TestKernel` never mentions a class its dependencies do not provide — PHPStan would be right to
complain, and it did, before the markers existed.

## Placeholders

`{{VENDOR}}` `{{PACKAGE}}` `{{PACKAGE_SLUG}}` `{{NAMESPACE}}` `{{NAMESPACE_JSON}}`
`{{BUNDLE_CLASS}}` `{{EXTENSION_CLASS}}` `{{ALIAS}}` `{{DESCRIPTION}}` `{{BUNDLE_TITLE}}`
`{{BUNDLE_TITLE_UNDERLINE}}` `{{YEAR}}` `{{AUTHOR_NAME}}` `{{AUTHOR_EMAIL}}`
`{{AUTHOR_HOMEPAGE}}` `{{COPYRIGHT_HOLDER}}` `{{PHP_CONSTRAINT}}` `{{BRANCH_ALIAS}}`

`{{NAMESPACE_JSON}}` exists because a namespace inside JSON needs its backslashes doubled:
`Jul6Art\ApiBundle` has to be written `Jul6Art\\ApiBundle` in `composer.json`, and substituting the
plain form there produces a file Composer refuses to read.

## Structure

```
bin/new-bundle          the generator, bash 3.2 compatible (macOS system bash)
common/overlay/         everything every bundle gets; *.tpl files are renamed after substitution
bricks/<name>/          optional additions, cumulative
```

## Traps already paid for

Three bundles came out of this generator — `api-bundle`, `ui-bundle`, `acl-bundle`. Each of the
following cost real time; none of them is caught by reading the code.

**A dependency the container needs to compile belongs in `require`, not `require-dev`.** The bricks
add dev dependencies only, deliberately — but a bundle whose services *inject* something from a
package has a hard requirement on it. `acl-bundle` had `symfony/security-bundle` in `require-dev`:
it installed cleanly in a consuming project and then failed to compile the container. The generated
`ContainerTest` is what caught it, which is the whole reason it exists.

**A prototype configuration node replaces the map, it does not merge it.** Ship a default table —
an icon set, a route map — and a project declaring one key silently loses all the others. Keep the
default on the node so `config:dump-reference` documents it, and re-merge it in the `Extension`:

```php
->setArgument('$icons', [...self::DEFAULTS, ...$config['icons']])
```

**A class a consumer has to double must not be `final`.** Rector will finalise everything it can,
and it is usually right. But a decision service, a resolver, anything that is a *seam* gets stubbed
in the consumer's own unit tests: sealing one turned 74 voter tests in the reference consumer into
`ClassIsFinalException` at once. Skip the rule for that file and say why in the docblock.

**Do not drop a type guarantee to satisfy PHPStan.** Facing a `generator.valueType` error, the first
reflex was to remove a `@template T` — which cost four consumer classes their typing. The right move
is to narrow the promise to what is provable, not to abandon it. And when the analyser refuses
something that *is* true, the honest fix is a different design, not a suppression: `phpstan.dist.neon`
here has no baseline on purpose.

**Assert on identity, not on content, wherever a value crosses a boundary.** `api-bundle` wrapped an
API Platform paginator in a lazy generator: every row survived, and `totalItems` disappeared from
every paginated response, because the serializer recognises `PaginatorInterface` and not
`Generator`. Thirty-five tests stayed green. Use `assertSame` on the object when the type is what
carries the information — and verify the regression test by mutation: disable the fix, watch it go
red, put the fix back.

**A `--prefer-lowest` job needs floors, not just ceilings.** Two of the traps above only ever showed
on the lowest dependency set, and both were invisible on the highest one: a `symfony/*` pin the CI's
`SYMFONY_REQUIRE` could not satisfy, and `doctrine/orm` old enough that the container DoctrineBundle
compiled called a method it does not have — reported from the compiled container, so the trace names
neither package. The `orm` brick now pins a floor, and the reason is written next to it. When a job
is red on lowest and green on highest, look at what a *dependency* requires of another dependency,
not at the code.

**A leaked exception handler is version-shaped.** The teardown that pops Symfony's `ErrorHandler`
when it recognises its array-callable form — which is what Symfony's own `KernelTestCase` does — pops
nothing on an older Symfony, and every kernel-booting test comes back risky. Drain the stack back to
the handler recorded before boot instead, with a bound so a replaced stack stops the loop.

**Write the test before believing a class's own docblock.** `ui-bundle`'s base form type documented
itself as usable directly and did not route to its own Twig block: the prefix Symfony derives from
`InputGroupAddOnType` is `input_group_add_on`, not `input_group_addon`.

**Flex thinks it is scaffolding an application, and two of its choices are actively wrong.** It is a
plugin, so `--no-scripts` does not stop its recipes: they drop `bin/console`, `public/index.php`,
`src/Kernel.php`, `config/packages/*.yaml`, `.env` and `compose.yaml` into a *bundle*, and they
rewrite `phpunit.xml.dist` to add `<env name="APP_ENV" value="dev"/>` directly under the template's
`<server name="APP_ENV" value="test" force="true"/>`. The `force` wins, so nothing breaks — until
someone reads the file and believes the wrong line. `bin/new-bundle` now deletes the skeleton and
restores the two template files; two bundles had already committed the whole thing before this was
noticed.

**`composer require` writes the constraint of what it resolved.** That is `^8.1` today, and the CI's
`SYMFONY_REQUIRE: 7.4.*` cannot satisfy it — it holds `symfony/security-http` at 7.4 while
`symfony/security-bundle: ^8.1` demands the 8.1 branch. The set becomes unsatisfiable on the
*highest* job, which is a counter-intuitive place to look. Constraints are normalised back to the
range the bundle declares, and the pass that follows is an `update` rather than an `install`, since
rewriting composer.json after a `require` desynchronises the lock.

**Extract less than the plan says when reading the code says so.** Three items planned for
`acl-bundle` stayed in the application: a service that turned out to be two lists of that
application's URLs, a twelve-line adapter over a base class already extracted, and an interface no
code in the bundle would ever call. A plan written before reading the code is corrected by reading
it — out loud, saying which item and why.

## License

The Symfony Bundle Generator is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

&copy; 2026 [jul6art](https://devinthehood.com)
