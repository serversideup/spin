# Testing Laravel with Spin

## Table of contents

- [Decision: which stack runs the tests](#decision-which-stack-runs-the-tests)
- [Inspecting the test config](#inspecting-the-test-config)
- [Running tests on the dev stack (default)](#running-tests-on-the-dev-stack-default)
- [`SPIN_ENV=ci` workflow (CI parity)](#spin_envci-workflow-ci-parity)
- [Running multiple Compose environments in parallel](#running-multiple-compose-environments-in-parallel)
- [Override networks and inherited services](#override-networks-and-inherited-services)
- [Common test failures](#common-test-failures)

---

## Decision: which stack runs the tests

Follow this decision tree before running tests:

1. Is the dev stack already running (`spin ps` shows services)? → Prefer `spin exec -T php …`
2. Does `phpunit.xml` override to sqlite `:memory:`? → Dev stack is plenty. Use `spin exec -T php …`
3. Does the test config rely on the real database/cache services? → Dev stack usually still works. Use `SPIN_ENV=ci` **only** when CI parity is explicitly required (reproducing CI-only failures, matching exact service versions, dry-running the pipeline before pushing).

**Never** start a parallel `SPIN_ENV=ci` stack just to run tests. The dev stack is faster and reuses already-warm containers.

---

## Inspecting the test config

Before choosing a stack, look at `phpunit.xml`, `phpunit.xml.dist`, or `phpunit.dist.xml` for the `<php>` block:

```xml
<php>
    <env name="DB_CONNECTION" value="sqlite"/>
    <env name="DB_DATABASE" value=":memory:"/>
    <env name="CACHE_STORE" value="array"/>
    <env name="QUEUE_CONNECTION" value="sync"/>
    <env name="SESSION_DRIVER" value="array"/>
</php>
```

| Config | Meaning | Stack |
|---|---|---|
| `DB_CONNECTION=sqlite` + `DB_DATABASE=:memory:` + `CACHE_STORE=array` | Tests are self-contained; no MariaDB/Redis/Mailpit needed | Dev stack |
| No `DB_CONNECTION` override, or explicit `mysql`/`pgsql` | Tests need the real services running | Dev stack (usually works) or `SPIN_ENV=ci` (for parity) |

---

## Running tests on the dev stack (default)

From a regular terminal, `-T` is optional — Compose auto-detects TTY. When invoked from an AI agent, CI pipeline, or wrapper script, pass `-T` defensively so auto-detection can't misfire:

```bash
./vendor/bin/spin exec -T php php artisan test
./vendor/bin/spin exec -T php php artisan test --filter=ExampleTest
./vendor/bin/spin exec -T php php artisan test --compact   # Laravel 9+
```

`php artisan test` runs PHPUnit and Pest tests transparently. If the project exposes a `composer test` script, prefer it:

```bash
./vendor/bin/spin exec -T php composer test
```

Use `spin run -T php …` instead of `spin exec -T php …` only when the dev stack is not currently running.

---

## `SPIN_ENV=ci` workflow (CI parity)

Use this workflow only when CI parity is explicitly needed. Copy this checklist and check items off as progress is made:

```
CI Parity Progress:
- [ ] Step 1: Verify credential parity (docker-compose.ci.yml vs phpunit.xml)
- [ ] Step 2: Namespace the CI project to prevent dev collisions
- [ ] Step 3: Start the CI stack detached
- [ ] Step 4: Wait for services to become ready
- [ ] Step 5: Run tests inside the CI stack
- [ ] Step 6: Tear down when finished
```

### Step 1: Verify credential parity

Database/cache environment variables in `docker-compose.ci.yml` must match what `phpunit.xml` expects. Mismatches surface as connection or auth errors mid-test.

### Step 2: Namespace the CI project

Give the CI override its own Compose project name so it does not clobber dev's containers, volumes, and networks. See [Running multiple Compose environments in parallel](#running-multiple-compose-environments-in-parallel).

### Step 3: Start the CI stack detached

```bash
SPIN_ENV=ci ./vendor/bin/spin up -d
```

### Step 4: Wait for services to become ready

A fresh MySQL/MariaDB container needs time to initialize data directories, create users, and accept connections. Poll with `spin exec`, or wait 10–30 seconds before running tests:

```bash
# Poll until MariaDB accepts connections
until SPIN_ENV=ci ./vendor/bin/spin exec -T mariadb mariadb-admin ping --silent 2>/dev/null; do
  sleep 1
done
```

### Step 5: Run tests inside the CI stack

```bash
SPIN_ENV=ci ./vendor/bin/spin exec -T php php artisan test
```

### Step 6: Tear down when finished

```bash
SPIN_ENV=ci ./vendor/bin/spin down
```

If the test config uses sqlite `:memory:`, skip every step above and use the dev stack.

---

## Running multiple Compose environments in parallel

`SPIN_ENV` controls which override file gets merged with `docker-compose.yml`:

| `SPIN_ENV` | Expands to |
|------------|------------|
| `dev` (default) | `docker compose -f docker-compose.yml -f docker-compose.dev.yml …` |
| `ci` | `docker compose -f docker-compose.yml -f docker-compose.ci.yml …` |
| `prod` | `docker compose -f docker-compose.yml -f docker-compose.prod.yml …` |

This applies to every Spin subcommand — `up`, `run`, `exec`, `down`, etc.

For `SPIN_ENV=ci` to run **alongside** the dev stack, the override file must declare its own project name. Without this, Compose computes the project name from the directory and the CI stack will collide with dev's containers, volumes, and networks:

```yaml
# docker-compose.ci.yml
name: myapp-ci

services:
  # ...
```

Verify the project name took effect:

```bash
SPIN_ENV=ci ./vendor/bin/spin ps    # Should show myapp-ci_* containers
./vendor/bin/spin ps                # Should show myapp_* (dev) containers unaffected
```

---

## Override networks and inherited services

When a Compose override defines a custom network, every inherited service that needs to talk on that network must be re-declared with the network attached. Compose does **not** automatically move inherited services onto networks defined in the override.

Skipping this causes "host not found" / "connection refused" errors between services that work fine in dev.

```yaml
# docker-compose.ci.yml
name: myapp-ci

networks:
  ci:

services:
  php:
    networks:
      - ci
  redis:        # Inherited from base — must be re-declared on the ci network
    networks:
      - ci
  traefik:      # Inherited from base — must be re-declared on the ci network
    networks:
      - ci
```

---

## Common test failures

| Symptom | Cause | Fix |
|---|---|---|
| Tests hang or output is garbled in an AI agent / CI run | Compose TTY auto-detection misfired in the wrapper context | Add `-T` to `spin exec`/`spin run` |
| `SQLSTATE[HY000] [2002] Connection refused` | Service not ready yet, or using `localhost` instead of container name | Wait for service (see Step 4), verify `DB_HOST=mysql` not `localhost` |
| Access denied on a fresh CI stack | `docker-compose.ci.yml` credentials drifted from `phpunit.xml` | Align env vars across both files |
| CI stack clobbered dev containers | Missing `name: myapp-ci` in `docker-compose.ci.yml` | Add a project name to the override |
| "host not found" between services | Custom network in override didn't include inherited services | Re-declare inherited services with the override's network |
| Tests pass locally, fail in CI (or vice versa) | PHP version, extension, or service version mismatch | Run the `SPIN_ENV=ci` workflow above to match exactly |
