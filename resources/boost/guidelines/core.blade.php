# Spin — Docker Workflow for Laravel

Spin is a lightweight CLI that wraps Docker Compose (development) and Docker Swarm (production) so you can replicate any environment on any machine.

## Key facts

- Spin follows Docker Compose syntax exactly — `spin up` runs `docker compose up`, `spin run` runs `docker compose run`, etc.
- Projects use a **Docker Compose overrides** pattern: a base `docker-compose.yml` merged with `docker-compose.$SPIN_ENV.yml`. `SPIN_ENV` defaults to `dev` (→ `docker-compose.dev.yml`). Common values: `dev`, `ci`, `prod`.
- Laravel projects use `serversideup/php` Docker images (fpm-nginx, fpm-apache, frankenphp, cli).
- The `.infrastructure/` folder stores configuration files (`conf/`) and gitignored volume data (`volume_data/`).
- In Docker, services connect via container name as hostname (`DB_HOST=mysql`, `REDIS_HOST=redis`), not `localhost`.

## Essential commands

| Command | Purpose |
|---------|---------|
| `spin up` | Start development environment (foreground) |
| `spin up --build` | Start and rebuild containers (recommended default if custom Dockerfile is used) |
| `spin exec <service> <cmd>` | Run a command in a running container (reuses live container, near-instant) |
| `spin run <service> <cmd>` | Run a one-off command in a new container (use when the stack is not running) |
| `spin deploy <env>` | Deploy to a provisioned server |
| `spin provision` | Provision and configure servers |

### `spin exec` vs `spin run`

- **`spin exec`** — use when the stack is running. Reuses the live container. This is the right default for `artisan`, `composer`, `npm`, tests, and ad-hoc commands during development.
- **`spin run`** — use when the stack is not running, or when a fresh container with different env vars or isolated state is needed. Creates (and removes) a new container each invocation.

### The `-T` flag (disable pseudo-TTY)

Compose auto-detects TTY by default, so interactive use from a terminal usually works without `-T`. **In AI agent, CI, and other subprocess contexts**, that auto-detection can misfire — Compose sees a TTY on stdin while downstream output is being captured, which can cause hangs, ANSI-garbled output, or prompts with nowhere to respond.

Pass `-T` as a defensive default when running commands from an AI agent, CI pipeline, or any wrapper script:

```bash
./vendor/bin/spin exec -T php php artisan test
./vendor/bin/spin run  -T php composer install
```

Omit `-T` when interactivity is actually needed (`artisan tinker` without `--execute`, interactive `make:*` prompts, `spin exec php bash`).

### Running Laravel tests

Prefer the **already-running dev stack** — it's faster than spinning up a parallel CI stack:

```bash
./vendor/bin/spin exec -T php php artisan test
./vendor/bin/spin exec -T php php artisan test --filter=ExampleTest
```

`php artisan test` works for both PHPUnit and Pest. If the project exposes a `composer test` script, prefer that via `spin exec -T php composer test`.

**Before assuming the dev stack is enough, inspect the test config** (`phpunit.xml`, `phpunit.xml.dist`, or `phpunit.dist.xml`):

- If `<php>` overrides `DB_CONNECTION` to `sqlite` with `DB_DATABASE=:memory:` (and `CACHE_STORE`/`QUEUE_CONNECTION`/`SESSION_DRIVER` set to `array`/`sync`), tests are self-contained — the dev stack is plenty.
- If the test config uses the real database/cache services, the dev stack usually still works. Reach for `SPIN_ENV=ci` only when CI parity is needed (reproducing a CI-only failure, matching exact service versions, dry-running the pipeline). See the **spin-laravel-development** skill's `TESTING.md` for the full CI-parity workflow.

## When to activate the full skill

Activate the **spin-laravel-development** skill for tasks involving:
- Docker Compose configuration or Dockerfile changes
- `serversideup/php` image settings
- Adding Laravel services (databases, queues, Horizon, Reverb)
- Running tests with CI parity (`SPIN_ENV=ci`)
- Running multiple Compose environments in parallel
- Server provisioning, deployment, or troubleshooting containerized environments

## Laravel Boost MCP setup

Since Spin runs PHP inside Docker (not on the host), Laravel Boost needs special configuration to start its MCP server. Spin ships `spin-mcp-wait.sh` which retries until Docker is ready and filters stdout for clean JSON-RPC communication.

Add these to your `.env` file:

```
BOOST_PHP_EXECUTABLE_PATH="./vendor/bin/spin-mcp-wait.sh ./vendor/bin/spin run -T php php"
BOOST_COMPOSER_EXECUTABLE_PATH="./vendor/bin/spin run php composer"
BOOST_NPM_EXECUTABLE_PATH="./vendor/bin/spin run node npm"
```

Then run:

```
spin run php php artisan boost:install
```

**IMPORTANT:** `spin-mcp-wait.sh` is exclusively for MCP server startup. NEVER use it to run commands. Always invoke `spin exec` (running stack) or `spin run` (stopped stack) directly.

If this error appears, drop `spin-mcp-wait.sh` and invoke `spin` directly:

```
Error: spin-mcp-wait.sh is only for starting the MCP server. Use 'spin' directly instead.
```

Correct:

```bash
./vendor/bin/spin exec -T php php artisan test
./vendor/bin/spin run -T php php artisan migrate
```

## Templates

- **Basic** (`spin new laravel`): Free open source template — <https://github.com/serversideup/spin-template-laravel-basic>
- **Pro** (`spin new laravel-pro`): Premium template with pre-configured services (Horizon, Reverb, databases, Vite, Mailpit, etc.) — <https://getspin.pro>

## Resources

- Spin docs: <https://serversideup.net/open-source/spin/docs>
- Spin docs (LLM-friendly): <https://serversideup.net/open-source/spin/llms.txt>
- serversideup/php docs: <https://serversideup.net/open-source/docker-php/docs>
- serversideup/php docs (LLM-friendly): <https://serversideup.net/open-source/docker-php/llms.txt>
- serversideup/php full docs (LLM-friendly): <https://serversideup.net/open-source/docker-php/llms-full.txt>
- serversideup/php environment variable reference: <https://serversideup.net/open-source/docker-php/docs/reference/environment-variable-specification>
- Spin Pro docs: <https://getspin.pro/docs>
