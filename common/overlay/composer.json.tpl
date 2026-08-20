{
    "name": "{{VENDOR}}/{{PACKAGE}}",
    "type": "symfony-bundle",
    "description": "{{DESCRIPTION}}",
    "homepage": "https://github.com/{{VENDOR}}/{{PACKAGE}}",
    "license": "MIT",
    "authors": [
        {
            "name": "{{AUTHOR_NAME}}",
            "email": "{{AUTHOR_EMAIL}}",
            "homepage": "{{AUTHOR_HOMEPAGE}}"
        }
    ],
    "require": {
        "php": "^8.5",
        "symfony/config": "^7.4 || ^8.0",
        "symfony/dependency-injection": "^7.4 || ^8.0",
        "symfony/http-kernel": "^7.4 || ^8.0",
        "symfony/yaml": "^7.4 || ^8.0"
    },
    "require-dev": {
        "friendsofphp/php-cs-fixer": "^3.68",
        "phpstan/extension-installer": "^1.4",
        "phpstan/phpstan": "^2.1",
        "phpstan/phpstan-phpunit": "^2.0",
        "phpstan/phpstan-symfony": "^2.0",
        "phpunit/phpunit": "^13.0",
        "rector/rector": "^2.0",
        "symfony/flex": "^2.4",
        "symfony/framework-bundle": "^7.4 || ^8.0",
        "symfony/phpunit-bridge": "^7.4 || ^8.0",
        "symfony/var-dumper": "^7.4 || ^8.0"
    },
    "autoload": {
        "psr-4": {
            "{{NAMESPACE_JSON}}\\": ""
        }
    },
    "autoload-dev": {
        "psr-4": {
            "{{NAMESPACE_JSON}}\\Tests\\": "Tests/"
        }
    },
    "config": {
        "allow-plugins": {
            "phpstan/extension-installer": true,
            "symfony/flex": true
        },
        "sort-packages": true
    },
    "extra": {
        "branch-alias": {
            "dev-master": "{{BRANCH_ALIAS}}"
        },
        "symfony": {
            "require": "7.4.*"
        }
    },
    "scripts": {
        "cs": "php-cs-fixer fix",
        "cs-check": "php-cs-fixer fix --dry-run --diff",
        "phpstan": "phpstan analyse --memory-limit=1G",
        "rector": "rector process",
        "rector-check": "rector process --dry-run",
        "test": "phpunit",
        "qa": [
            "@cs-check",
            "@rector-check",
            "@phpstan",
            "@test"
        ]
    }
}
