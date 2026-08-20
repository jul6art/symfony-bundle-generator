<?php

declare(strict_types=1);

namespace {{NAMESPACE}}\Tests\Functional;

use {{NAMESPACE}}\Tests\Fixtures\TestKernel;
use PHPUnit\Framework\TestCase;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\ErrorHandler\ErrorHandler;

abstract class AbstractFunctionalTestCase extends TestCase
{
    private ?TestKernel $kernel = null;

    #[\Override]
    protected function tearDown(): void
    {
        $this->kernel?->shutdown();
        $this->kernel = null;

        self::restoreSymfonyExceptionHandler();

        parent::tearDown();
    }

    /**
     * Boots a kernel and returns its container.
     *
     * The build directory is keyed on the scenario so two configurations never share a compiled
     * container — a stale one silently invalidates the assertions, and it is the single most
     * confusing failure mode of a bundle test suite.
     *
     * @param array<string, mixed> $bundleConfig
     */
    final protected function boot(
        string $environment = 'test',
        array $bundleConfig = [],
        // {{#orm}}
        bool $withOrm = false,
        // {{/orm}}
        // {{#security}}
        bool $withSecurity = false,
        // {{/security}}
    ): ContainerInterface {
        $uniqueId = substr(md5(serialize([
            $bundleConfig,
            // {{#orm}}
            $withOrm,
            // {{/orm}}
            // {{#security}}
            $withSecurity,
            // {{/security}}
        ])), 0, 12);

        // Arguments nommés : une brique absente retire son paramètre du kernel, et un appel
        // positionnel se décalerait silencieusement.
        $this->kernel = new TestKernel(
            $environment,
            $bundleConfig,
            // {{#orm}}
            withOrm: $withOrm,
            // {{/orm}}
            // {{#security}}
            withSecurity: $withSecurity,
            // {{/security}}
            uniqueId: $uniqueId,
        );
        $this->kernel->boot();

        return $this->kernel->getContainer();
    }

    /**
     * FrameworkBundle::boot() calls ErrorHandler::register(), which leaves one exception handler
     * on the stack. Booting is our own side effect, so we pop it back off instead of letting
     * PHPUnit report leaked global state — `beStrictAboutChangesToGlobalState` is on, and rightly.
     */
    private static function restoreSymfonyExceptionHandler(): void
    {
        $handler = set_exception_handler(null);
        restore_exception_handler();

        if (\is_array($handler) && $handler[0] instanceof ErrorHandler) {
            restore_exception_handler();
        }
    }
}
