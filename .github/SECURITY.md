# Security Policy

## Supported versions

This repository is a **bundle generator**, not a runtime dependency: nothing here
is installed into a generated bundle, and there is no released package to
upgrade. Only the tip of `master` is maintained.

| Version | Supported |
| --- | --- |
| `master` | ✅ |
| any older commit or fork | ❌ |

## What is in scope

A vulnerability here is a defect in what the generator *writes* or *runs*:

* **An insecure default in a generated template** — most of all in the
  `security` brick, whose generated voter, actor resolution and test firewall
  are the shape every bundle in this ecosystem copies. A voter template that
  fails open, or a firewall template that authorises what it should refuse,
  reproduces itself in every bundle generated afterwards.
* **A harness that hides a problem instead of catching it** — a generated
  `phpstan.dist.neon` that quietly excludes code, a `phpunit.xml.dist` that
  swallows deprecations from the bundle's own code, or a CI workflow whose
  failing step cannot fail the build. These are security-relevant because the
  whole point of the harness is to make defects visible.
* **A flaw in `bin/new-bundle`** — a placeholder substitution that allows
  injection into a generated PHP file, an unsafe path expansion (a bundle name
  or `--dir=` escaping its directory), a file written with permissions it should
  not have.
* **A generated workflow with excessive permissions** — the templates grant
  `contents: read`; anything wider, or a workflow trigger that would run
  untrusted code from a pull request with access to secrets, is in scope.
* **A secret committed to this repository** by accident.

Out of scope: vulnerabilities in Symfony, PHPStan, Rector, PHPUnit or any other
third-party tool the templates invoke — report those to the project that owns
the code. Also out of scope: a bundle *you* generated and then wrote yourself,
unless the generated code is what introduced the problem.

## Reporting a vulnerability

**Do not open a public issue for a security problem.**

Use [GitHub's private vulnerability reporting](https://github.com/jul6art/symfony-bundle-generator/security/advisories/new)
(the **Security** tab → *Report a vulnerability*). It opens a draft advisory only
you and the maintainers can read, and it is the channel this project prefers —
no email address needs to be published for it to work.

Please include:

* the `./bin/new-bundle` command line, bricks included,
* the file in **this** repository (`common/overlay/…`, `bricks/<name>/…`,
  `bin/new-bundle`), not only the path inside your generated bundle,
* what an attacker gains, and whether a bundle already generated is affected.

## What to expect

* An acknowledgement within **7 days**.
* An assessment — accepted, out of scope, or needing more detail — within
  **14 days**.
* For an accepted report: a fix on `master`, and credit unless you ask
  otherwise.

Because generated bundles are copies rather than dependencies, a fix here does
not reach anything already generated. Accepted reports affecting code already
shipped into bundles are published as a
[security advisory](https://github.com/jul6art/symfony-bundle-generator/security/advisories)
describing the patch to apply by hand — and, where the affected bundle is one of
the `jul6art/*` packages, fixed there too.

Please give the maintainers a reasonable window to ship a fix before disclosing
publicly. This project runs no bug-bounty programme and offers no payment.
