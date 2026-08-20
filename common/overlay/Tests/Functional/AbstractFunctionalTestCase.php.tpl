<?php

declare(strict_types=1);

namespace {{NAMESPACE}}\Tests\Functional;

use {{NAMESPACE}}\Tests\Fixtures\TestKernel;
use PHPUnit\Framework\TestCase;
use Symfony\Component\DependencyInjection\ContainerInterface;

abstract class AbstractFunctionalTestCase extends TestCase
{
    private ?TestKernel $kernel = null;

    /**
     * The top of the exception-handler stack before anything of ours ran, so tearDown knows how far
     * to unwind. Captured in setUp rather than at boot: a test may boot more than once.
     */
    private mixed $handlerBeforeBoot = null;

    #[\Override]
    protected function setUp(): void
    {
        parent::setUp();

        $this->handlerBeforeBoot = self::currentExceptionHandler();
    }

    #[\Override]
    protected function tearDown(): void
    {
        $this->kernel?->shutdown();
        $this->kernel = null;

        $this->restoreExceptionHandlers();

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
     * Pops every exception handler booting the kernel pushed, and no more.
     *
     * `FrameworkBundle::boot()` calls `ErrorHandler::register()`, which pushes a handler and never
     * removes it. Booting is our own side effect, so PHPUnit is right to report the leak —
     * `beStrictAboutChangesToGlobalState` is on.
     *
     * ⚠️ The obvious version — pop once if the top handler is a Symfony `ErrorHandler` — is what
     * Symfony's own `KernelTestCase` does, and it is not enough here: on the **lowest** dependency
     * set the leaked handler is not that shape, so nothing was popped and all 26 filter tests came
     * back risky. On the highest set they were green, which is the worst kind of difference to
     * chase. So the stack is drained back to the handler that was installed before boot, whatever
     * either version happens to push.
     *
     * The bound is a safety net, not a limit: if the handler recorded before boot never reappears —
     * something replaced the stack rather than pushing onto it — this must stop rather than spin.
     */
    private function restoreExceptionHandlers(): void
    {
        for ($i = 0; $i < 16; ++$i) {
            if (self::currentExceptionHandler() === $this->handlerBeforeBoot) {
                return;
            }

            restore_exception_handler();
        }
    }

    /**
     * Reads the top of the exception-handler stack without changing it: `set_exception_handler()`
     * returns the previous handler, and `restore_exception_handler()` undoes the push it just made.
     */
    private static function currentExceptionHandler(): ?callable
    {
        $handler = set_exception_handler(null);
        restore_exception_handler();

        return $handler;
    }
}
