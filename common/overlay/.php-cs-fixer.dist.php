<?php

declare(strict_types=1);

// ⚠️ Les répertoires du bundle sont listés, plutôt que `->in(__DIR__)->exclude('vendor')`.
//
// Flex est un plugin : il applique ses recipes à chaque `composer install`, **y compris en CI**, et
// dépose un squelette d'application — `bin/phpunit`, `config/*`, `src/Kernel.php`, `public/`. Ces
// fichiers ne suivent pas les règles d'ici (`declare_strict_types`, `@PHP85Migration`), et un
// balayage large les analyse : la CI passait au rouge sur du code que le bundle n'écrit pas et ne
// livre pas. Les retirer localement ne suffit pas, la CI les recrée.
//
// Un répertoire ajouté au bundle doit donc être ajouté ici — et dans `phpstan.dist.neon`, qui liste
// ses chemins pour la même raison.
$finder = new PhpCsFixer\Finder()
    // Seuls les répertoires du bundle. `in()` n'accepte que des répertoires ; les fichiers PHP de
    // la racine passent par `append()` juste après.
    ->in(array_values(array_filter(
        [
            __DIR__.'/DependencyInjection',
            __DIR__.'/Tests',
        ],
        is_dir(...),
    )))
    ->append(array_values(array_filter(
        [
            __FILE__,
            __DIR__.'/rector.php',
            __DIR__.'/{{BUNDLE_CLASS}}.php',
        ],
        is_file(...),
    )));

return new PhpCsFixer\Config()
    ->setRiskyAllowed(true)
    ->setFinder($finder)
    ->setRules([
        '@Symfony' => true,
        '@Symfony:risky' => true,
        '@PHP85Migration' => true,
        'declare_strict_types' => true,
        // Keeps the leading backslash on native calls, as the bundle sources do.
        'native_function_invocation' => [
            'include' => ['@compiler_optimized'],
            'scope' => 'namespaced',
            'strict' => true,
        ],
        'ordered_class_elements' => [
            'order' => ['use_trait', 'case', 'constant', 'property', 'construct', 'destruct', 'magic', 'phpunit', 'method'],
        ],
        'php_unit_test_case_static_method_calls' => ['call_type' => 'self'],
    ]);
