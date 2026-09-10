## What this changes

<!-- One subject per pull request. Say what a generated bundle will contain, or
     stop containing. -->

Closes #

## Where

- [ ] `common/overlay/` — **lands in every generated bundle**
- [ ] `bricks/console/`
- [ ] `bricks/form/`
- [ ] `bricks/orm/`
- [ ] `bricks/security/`
- [ ] `bricks/twig/`
- [ ] a new brick
- [ ] `bin/new-bundle`
- [ ] documentation only (`README.md`, `.github/`)

## Validation

The standard is the README's: **`composer qa` passes on a freshly generated
bundle — if it does not, that is the generator's bug.** Bricks are cumulative,
so combinations are where the bugs are.

| Generated with | `composer install` | `composer qa` |
| --- | --- | --- |
| <!-- (bare) --> | | |
| <!-- --with=orm,security --> | | |

```
# the exact ./bin/new-bundle command lines you ran
```

<details>
<summary><code>composer qa</code> output</summary>

```
```

</details>

- [ ] `composer qa` is green on every generated bundle listed above, with no new
      PHPStan baseline entry
- [ ] `./bin/new-bundle probe --dry-run` still prints a coherent plan
- [ ] I changed a generated CI workflow, and I let it actually run on a scratch
      repository *(workflow changes only)*

## The rules the templates encode

- [ ] Nothing was added to `require` — dev dependencies plus `suggest` and
      conditional registration
- [ ] Optional dependencies are registered from the extension behind
      `class_exists()`, never by an attribute on a vendor class
- [ ] Anything depending on another *service* goes in a compiler pass, not in the
      extension
- [ ] The harness keeps its teeth — `level: max` with no baseline, PHPUnit
      failing on deprecations, the `highest` **and** `lowest` matrix
- [ ] Every guard I touched kept the comment explaining why it exists
- [ ] A new brick is a data directory; `bin/new-bundle` was not taught about it
- [ ] The README is updated *(new brick, option or placeholder)*

## Notes for the reviewer

<!-- Trade-offs, anything left out on purpose, and which bundle in the ecosystem
     prompted this. -->
