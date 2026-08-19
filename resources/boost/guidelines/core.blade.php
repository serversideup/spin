# Spin — Docker Workflow for Laravel

Spin is a lightweight CLI that wraps Docker Compose (development) and Docker Swarm (production). It follows Docker Compose syntax exactly — `spin up` runs `docker compose up`, `spin exec` runs `docker compose exec`, etc., and official Docker Compose flags pass through (e.g. `spin logs -f php`).

## Key facts

- **Compose overrides pattern**: a base `docker-compose.yml` is merged with `docker-compose.$SPIN_ENV.yml`. `SPIN_ENV` defaults to `dev`.
- **Service names come from the project's `docker-compose.yml`** — verify them there before running commands. Templates typically use `php`, `node`, `mysql`, etc., but projects are free to rename or restructure anything.
- Inside Docker, services connect via service name as hostname (`DB_HOST=mysql`), not `localhost`.
- Laravel projects typically use `serversideup/php` images and store config/volume data under `.infrastructure/` — check the project's files rather than assuming this layout.

## Running commands

- `spin exec <service> <cmd>` — stack is running. Reuses the live container; default for `artisan`, `composer`, `npm`, and tests.
- `spin run <service> <cmd>` — stack is not running, or isolated state is needed. New container per invocation.
- Pass `-T` when invoking from an AI agent, CI, or any subprocess — Compose's TTY auto-detection can misfire there, causing hangs or garbled output. Omit `-T` only for genuinely interactive commands (e.g. `artisan tinker`).

Run tests on the already-running dev stack:

```bash
./vendor/bin/spin exec -T php php artisan test
```

## When to activate the full skill

Activate **spin-laravel-development** for: Docker Compose or Dockerfile changes, `serversideup/php` image settings, adding Laravel services (databases, queues, Horizon, Reverb), test strategy and CI parity (`SPIN_ENV=ci`), parallel Compose environments, server provisioning, deployment, or troubleshooting containerized environments.

## Laravel Boost MCP

Spin runs PHP inside Docker, so Boost's MCP server needs the bundled bridge script. Configure via `.env`:

```
BOOST_PHP_EXECUTABLE_PATH="./vendor/bin/spin-mcp-wait.sh ./vendor/bin/spin run -T php php"
BOOST_COMPOSER_EXECUTABLE_PATH="./vendor/bin/spin run php composer"
BOOST_NPM_EXECUTABLE_PATH="./vendor/bin/spin run node npm"
```

**NEVER use `spin-mcp-wait.sh` to run commands** — it is exclusively for MCP server startup. Always invoke `spin exec` (running stack) or `spin run` (stopped stack) directly.

## Resources

- Templates: `spin new laravel` (free, open source) or `spin new laravel-pro` (premium, pre-configured services) — <https://getspin.pro>
- Spin docs (LLM-friendly): <https://serversideup.net/open-source/spin/llms.txt>
- serversideup/php docs (LLM-friendly): <https://serversideup.net/open-source/docker-php/llms.txt>
