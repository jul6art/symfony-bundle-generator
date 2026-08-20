<p align="center">
    <a href="https://devinthehood.com"><img src="https://github.com/jul6art/symfony-skeleton-generator/blob/master/public/img/logo.png?raw=true" alt="logo dev in the hood" width="400"></a>
</p>

<p align="center">
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
├── .github/workflows/ci.yml     tests × {highest, lowest}, phpstan, cs + rector
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

## License

Open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

&copy; 2026 [jul6art](https://devinthehood.com)
