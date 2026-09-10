# Security Policy

## Supported versions

`{{VENDOR}}/{{PACKAGE}}` is installed by other applications through Composer, so
a fix here reaches them the moment they update. Only the current major line gets
one.

| Version | Supported |
| --- | --- |
| `1.x` | ✅ |
| any older tag or fork | ❌ |

Support means security fixes on the latest release of that line — upgrade to it
before reporting, in case the problem is already gone.

## What is in scope

<!-- Bundle author: replace this list with what is actually dangerous about
     *this* bundle. A policy that names the real attack surface gets useful
     reports; a generic one gets none. Ask what an attacker would aim at: the
     decision it takes, the input it parses, the output it renders, the query it
     builds, the topic it publishes to. -->

A vulnerability here is a defect that lets an application using this bundle do
something it refused, or reveal something it never meant to. Typically:

* **A check that fails open** — any code path that cannot reach a verdict and
  allows instead of refusing.
* **A value reaching a query unbound** — request input interpolated into DQL or
  SQL rather than passed as a parameter, including a property or column name
  taken from the caller.
* **Over-exposure through serialization or rendering** — a field, an identifier
  or an error message leaving the application through a group, a template or an
  exception it was not meant to leave through.
* **A secret in a log, a template or a client-visible variable** — key material,
  a token, a password or personal data written where whoever reads a stack trace
  can read it too.
* **An unbounded operation** reachable from a client — a page size, a loop or an
  allocation a caller can raise at will, which is a denial of service against
  the application's own database.

Out of scope: vulnerabilities in Symfony, Doctrine or any other third-party
package — report those to the project that owns the code, and they will reach
you through your own `composer update`. Also out of scope: an application that
misconfigures this bundle in a way the README warns against, though a warning
that turns out to be easy to miss is worth an issue of its own.

## Reporting a vulnerability

**Do not open a public issue for a security problem.**

Use [GitHub's private vulnerability reporting](https://github.com/{{VENDOR}}/{{PACKAGE}}/security/advisories/new)
(the **Security** tab → *Report a vulnerability*). It opens a draft advisory only
you and the maintainers can read, and it is the channel this project prefers —
no email address needs to be published for it to work.

<!-- Bundle author: private reporting has to be switched on for that link to
     work for anyone outside the repository. Once, per repository:
     gh api -X PUT repos/{{VENDOR}}/{{PACKAGE}}/private-vulnerability-reporting -->

Please include:

* the version of `{{VENDOR}}/{{PACKAGE}}` and of Symfony you are running,
* the relevant part of your `{{ALIAS}}` configuration,
* the shortest reproduction you have — ideally a failing test against this
  repository, since that is what a fix will be built on,
* what an attacker gains: which check is bypassed, which data is read or
  written, and whether authentication is required.

## What to expect

* An acknowledgement within **7 days**.
* An assessment — accepted, out of scope, or needing more detail — within
  **14 days**.
* For an accepted report: a fix released on the supported line, a
  [security advisory](https://github.com/{{VENDOR}}/{{PACKAGE}}/security/advisories)
  describing the impact and the version to upgrade to, and credit in it unless
  you ask otherwise.

Please give the maintainers a reasonable window to ship a release before
disclosing publicly. This project runs no bug-bounty programme and offers no
payment.
