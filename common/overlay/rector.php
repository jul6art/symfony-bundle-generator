<?php

declare(strict_types=1);

use Rector\CodeQuality\Rector\ClassMethod\LocallyCalledStaticMethodToNonStaticRector;
use Rector\Config\RectorConfig;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\Renaming\Rector\Name\RenameClassRector;

return RectorConfig::configure()
    ->withPaths([
        __DIR__.'/{{BUNDLE_CLASS}}.php',
        __DIR__.'/DependencyInjection',
        __DIR__.'/Tests',
    ])
    // No argument: the target PHP version is read from the "php" constraint in
    // composer.json, so the rule set follows the bundle instead of drifting.
    ->withPhpSets()
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        typeDeclarations: true,
        privatization: true,
        earlyReturn: true,
        doctrineCodeQuality: true,
        symfonyCodeQuality: true,
    )
    ->withAttributesSets(symfony: true, doctrine: true, phpunit: true)
    ->withComposerBased(doctrine: true, symfony: true, phpunit: true)
    ->withSkip([
        // Ce déplacement de namespace vise `Symfony\Component\DependencyInjection\Kernel\BundleInterface`,
        // qui n'existe pas en Symfony 8.1 — et le bundle déclare `^7.4 || ^8.0`, donc il ne peut
        // pas s'appuyer sur une classe présente d'un seul côté. `HttpKernel\Bundle\BundleInterface`
        // existe sur les deux branches : c'est celle-là qu'on garde.
        RenameClassRector::class => [
            __DIR__.'/Tests/Fixtures/TestKernel.php',
        ],
        // Pure helpers are deliberately static: it documents that they touch no state.
        LocallyCalledStaticMethodToNonStaticRector::class,
        // Doctrine entities keep their mapped properties out of the constructor, so
        // the test fixtures stay representative of real consumer code.
        ClassPropertyAssignToConstructorPromotionRector::class => [
            __DIR__.'/Tests/Fixtures/Entity',
        ],
    ])
    ->withImportNames(importShortClasses: false, removeUnusedImports: true);
