<p align="center">
    <a href="{{AUTHOR_HOMEPAGE}}"><img src="https://github.com/jul6art/symfony-skeleton-generator/blob/master/public/img/logo.png?raw=true" alt="logo dev in the hood" width="400"></a>
</p>

{{BUNDLE_TITLE}}
{{BUNDLE_TITLE_UNDERLINE}}

<p align="left">
    <a href="https://opensource.org/licenses/MIT" target="_blank"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License"></a>
    <img src="https://img.shields.io/static/v1?label=stable&message=v1&color=0ea5e9" alt="Version">
</p>

{{DESCRIPTION}}

Requirements
------------

- PHP {{PHP_CONSTRAINT}}
- Symfony ^7.4 || ^8.0

Installation
------------

```shell
composer require {{VENDOR}}/{{PACKAGE}}
```

Then register it in `config/bundles.php` (Flex does this for you):

```php
{{NAMESPACE}}\{{BUNDLE_CLASS}}::class => ['all' => true],
```

Configuration
-------------

```yaml
# config/packages/{{ALIAS}}.yaml
{{ALIAS}}:
    # Leaves the bundle installed and inert when false.
    enabled: true
```

`{{ALIAS}}.enabled` is also exposed as a container parameter.

Usage
-----

<!--
    Write what a reader has to DO, not what the bundle contains. A line in a table saying a class
    exists has never helped anyone: someone must be able to use a brick without opening its code.

    For a parent class, show the contract — the methods to implement, one complete example, what
    the class gives back.

    For anything driven by an attribute, four things are needed, because the attribute does not
    say what it triggers:

      1. the annotation in situ, on a realistic class;
      2. WHAT EXECUTES IT, and when — a command? a Doctrine listener? a request listener? Without
         this, a reader assumes an attribute acts on its own;
      3. what to wire on the application side to get anything out of it — the event to subscribe
         to, the service to implement, the table to create, the configuration to set;
      4. THE TRAP: what is irreversible, what must be measured first, what silently does nothing
         when an optional package is missing.
-->

Quality assurance
-----------------

```shell
composer qa            # cs-check + rector-check + phpstan (level max) + phpunit
```

Run `composer qa`, not the single tool you have in mind: the CI's "Coding standards" job runs
Rector too, and its `lowest deps` job installs the minimum of every constraint — which is where
this ecosystem has repeatedly found what a local run could not.

`extra.symfony.require` states which Symfony line this bundle targets; the CI enforces it with
`SYMFONY_REQUIRE` on both the highest and the lowest job. A local `composer install` may still
resolve a newer Symfony, which broadens what you exercise rather than narrowing it — but it means
the toolchain can propose something that only makes sense on one branch. `rector.php` skips one
such rule already, with the reason written next to it.

Whatever you do, keep the code free of classes that exist on only one of the declared branches.
A bundle promising `^7.4 || ^8.0` has to hold both.

License
-------

{{BUNDLE_TITLE}} is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

&copy; {{YEAR}} [{{AUTHOR_NAME}}]({{AUTHOR_HOMEPAGE}})
