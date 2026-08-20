<?php

declare(strict_types=1);

namespace {{NAMESPACE}}\Tests\Fixtures;

        // {{#orm}}
use Doctrine\Bundle\DoctrineBundle\DoctrineBundle;
        // {{/orm}}
use {{NAMESPACE}}\{{BUNDLE_CLASS}};
use Symfony\Bundle\FrameworkBundle\FrameworkBundle;
        // {{#security}}
use Symfony\Bundle\SecurityBundle\SecurityBundle;
        // {{/security}}
use Symfony\Component\Config\Loader\LoaderInterface;
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\Compiler\PassConfig;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\HttpKernel\Bundle\BundleInterface;
use Symfony\Component\HttpKernel\Kernel;

/**
 * Minimal application kernel used by the functional tests.
 *
 * A bundle is only really proven by booting a container: half of what goes wrong in a bundle is
 * wiring, not logic — a service registered under the wrong condition, a decoration that does not
 * take, a tag Doctrine never sees. None of that shows up in a unit test.
 *
 * The optional pieces are flags rather than separate kernels so a test can ask for exactly the
 * environment its scenario needs, and no more: booting Doctrine to check a configuration node
 * costs a second per test for nothing.
 */
final class TestKernel extends Kernel
{
    /**
     * @param array<string, mixed> $bundleConfig configuration for the "{{ALIAS}}" extension
        // {{#orm}}
     * @param bool                 $withOrm      registers DoctrineBundle on in-memory SQLite,
     *                                           mapped on Tests/Fixtures/Entity
        // {{/orm}}
        // {{#security}}
     * @param bool                 $withSecurity registers SecurityBundle with a stateless
     *                                           firewall — needed by anything resolving an actor
        // {{/security}}
     * @param string               $uniqueId     keys the build directory, so two scenarios never
     *                                           share a compiled container while identical ones
     *                                           still reuse the cache
     */
    public function __construct(
        string $environment,
        private readonly array $bundleConfig = [],
        // {{#orm}}
        private readonly bool $withOrm = false,
        // {{/orm}}
        // {{#security}}
        private readonly bool $withSecurity = false,
        // {{/security}}
        private readonly string $uniqueId = 'default',
    ) {
        // Debug mode installs Symfony's error handler and never removes it, which PHPUnit
        // rightly reports as leaking global state.
        parent::__construct($environment, false);
    }

    /**
     * @return iterable<BundleInterface>
     */
    #[\Override]
    public function registerBundles(): iterable
    {
        yield new FrameworkBundle();

        // {{#security}}
        if ($this->withSecurity) {
            yield new SecurityBundle();
        }
        // {{/security}}

        // {{#orm}}
        if ($this->withOrm) {
            yield new DoctrineBundle();
        }
        // {{/orm}}

        yield new {{BUNDLE_CLASS}}();
    }

    #[\Override]
    public function registerContainerConfiguration(LoaderInterface $loader): void
    {
        $loader->load($this->configure(...));
    }

    #[\Override]
    public function getProjectDir(): string
    {
        return \dirname(__DIR__, 2);
    }

    #[\Override]
    public function getCacheDir(): string
    {
        return $this->buildDir().'/cache';
    }

    #[\Override]
    public function getLogDir(): string
    {
        return $this->buildDir().'/log';
    }

    /**
     * Marks the services the tests need to reach.
     *
     * Symfony inlines or removes private services, so `$container->get()` on one throws "has been
     * removed or inlined" — a message that reads like a bug in the bundle and is not. Listing them
     * here is the least intrusive fix; the alternative, making them public in the extension, would
     * change what the bundle exposes to real applications for the sake of a test.
     *
     * Beware: an id can change during compilation. A decorated service is renamed, so asserting on
     * `some.service` after decorating it tells you nothing — assert on what was *injected*
     * instead.
     */
    #[\Override]
    protected function build(ContainerBuilder $container): void
    {
        $container->addCompilerPass(new class implements CompilerPassInterface {
            #[\Override]
            public function process(ContainerBuilder $container): void
            {
                $exposed = [
                    'doctrine.orm.default_entity_manager',
                    'event_dispatcher',
                    'request_stack',
                    'security.token_storage',
                    // Add the bundle's own services here as the tests need them.
                ];

                foreach ($container->getDefinitions() as $id => $definition) {
                    if (\in_array($id, $exposed, true)) {
                        $definition->setPublic(true);
                    }
                }

                foreach ($container->getAliases() as $id => $alias) {
                    if (\in_array($id, $exposed, true)) {
                        $alias->setPublic(true);
                    }
                }
            }
        }, PassConfig::TYPE_BEFORE_REMOVING, 100);
    }

    private function buildDir(): string
    {
        return \sprintf('%s/{{PACKAGE_SLUG}}-tests/%s/%s', sys_get_temp_dir(), $this->uniqueId, $this->environment);
    }

    private function configure(ContainerBuilder $container): void
    {
        $container->loadFromExtension('framework', [
            'secret' => '{{PACKAGE_SLUG}}-tests',
            'http_method_override' => false,
            'handle_all_throwables' => true,
            'php_errors' => ['log' => true],
        ]);

        // {{#security}}
        if ($this->withSecurity) {
            $container->loadFromExtension('security', [
                'providers' => ['in_memory' => ['memory' => null]],
                'firewalls' => ['main' => ['security' => false]],
            ]);
        }
        // {{/security}}

        // {{#orm}}
        if ($this->withOrm) {
            $this->configureDoctrine($container);
        }
        // {{/orm}}

        $container->loadFromExtension('{{ALIAS}}', $this->bundleConfig);
    }

    // {{#orm}}
    /**
     * The whole `Tests/Fixtures/Entity` directory is mapped, so a new fixture entity is picked up
     * without touching this method.
     */
    private function configureDoctrine(ContainerBuilder $container): void
    {
        $container->loadFromExtension('doctrine', [
            'dbal' => [
                'driver' => 'pdo_sqlite',
                'memory' => true,
            ],
            'orm' => [
                'controller_resolver' => ['auto_mapping' => false],
                'mappings' => [
                    '{{BUNDLE_CLASS}}Tests' => [
                        'type' => 'attribute',
                        'dir' => __DIR__.'/Entity',
                        'prefix' => '{{NAMESPACE}}\\Tests\\Fixtures\\Entity',
                        'is_bundle' => false,
                    ],
                ],
            ],
        ]);
    }
    // {{/orm}}
}
