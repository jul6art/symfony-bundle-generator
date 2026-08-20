<?php

declare(strict_types=1);

namespace {{NAMESPACE}}\Tests\DependencyInjection;

use {{NAMESPACE}}\DependencyInjection\Configuration;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Config\Definition\Exception\InvalidTypeException;
use Symfony\Component\Config\Definition\Processor;

/**
 * The configuration tree is public API: an application writes against it and a rename breaks
 * someone's deployment. Assert the **whole** processed shape rather than one key at a time — that
 * is what makes an accidental addition or a changed default visible in a diff.
 */
#[CoversClass(Configuration::class)]
final class ConfigurationTest extends TestCase
{
    public function testItsRootNodeIsTheBundleAlias(): void
    {
        self::assertSame('{{ALIAS}}', new Configuration()->getConfigTreeBuilder()->buildTree()->getName());
    }

    public function testItAppliesItsDefaults(): void
    {
        self::assertSame(['enabled' => true], $this->process([]));
    }

    public function testLaterConfigsOverrideEarlierOnes(): void
    {
        self::assertSame(['enabled' => true], $this->process([['enabled' => false], ['enabled' => true]]));
    }

    /**
     * A `booleanNode` refuses anything but a boolean, which is what you want — and the reason an
     * env var cannot gate service registration.
     */
    #[DataProvider('nonBooleanValues')]
    public function testItRejectsNonBooleanValues(mixed $value): void
    {
        $this->expectException(InvalidTypeException::class);

        $this->process([['enabled' => $value]]);
    }

    /**
     * @return iterable<string, array{mixed}>
     */
    public static function nonBooleanValues(): iterable
    {
        yield 'string' => ['yes'];
        yield 'int' => [0];
        yield 'array' => [[]];
    }

    /**
     * @param array<int, array<string, mixed>> $configs
     *
     * @return array<array-key, mixed>
     */
    private function process(array $configs): array
    {
        return new Processor()->processConfiguration(new Configuration(), $configs);
    }
}
