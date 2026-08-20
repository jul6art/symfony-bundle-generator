<?php

declare(strict_types=1);

namespace {{NAMESPACE}};

use Symfony\Component\HttpKernel\Bundle\Bundle;

/**
 * {{BUNDLE_TITLE}}.
 *
 * Registering a compiler pass? Override `build()` here — a pass is how you check that a service
 * the application may or may not have actually exists, which an extension cannot do (extensions
 * run before the other bundles have had their say):
 *
 * ```php
 * #[\Override]
 * public function build(ContainerBuilder $container): void
 * {
 *     parent::build($container);
 *
 *     $container->addCompilerPass(new SomethingOptionalPass());
 * }
 * ```
 */
class {{BUNDLE_CLASS}} extends Bundle
{
}
