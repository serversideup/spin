---
name: spin-laravel-development
description: "Develops and deploys Laravel applications using Spin and serversideup/php Docker images. Covers Docker Compose configuration, development environment setup, container commands, Laravel service configuration (databases, queues, Horizon, Reverb), server provisioning, and deployment workflows. Use when working with Spin, Docker Compose files, serversideup/php images, spin commands, configuring Laravel services in Docker, or deploying Laravel apps to production servers."
---

# Spin Laravel Development

## Table of contents

- [Safety guardrails](#safety-guardrails)
- [Laravel Boost MCP](#laravel-boost-mcp)
- [How Spin works](#how-spin-works)
- [Project structure](#project-structure)
- [Dockerfile pattern](#dockerfile-pattern)
- [Development workflow](#development-workflow)
- [serversideup/php images](#serversideupphp-images)
- [Laravel services](#laravel-services)
- [Deployment](#deployment)
- [Server provisioning](#server-provisioning)
- [Common pitfalls](#common-pitfalls)
- [Reference files](#reference-files)

## Safety guardrails

- **NEVER** run commands that could destroy data without explicitly confirming with the user first. This includes `docker system prune`, `docker volume rm`, dropping databases, removing services, or any destructive operation.
- If Spin fails to run, it is likely because Docker Desktop is not started. Check with `docker info`. If Docker is not running, tell the user to start Docker Desktop and offer to retry before continuing.
- Always prefer `spin run` over `spin exec` for one-off commands — it is safer because it creates an isolated container.

## Laravel Boost MCP

Spin runs PHP inside Docker, not on the host machine. Laravel Boost's MCP server needs a bridge script (`spin-mcp-wait.sh`) that retries until Docker is ready and filters Docker's stdout noise to preserve the JSON-RPC stdio protocol.

The required `.env` configuration:

```env
BOOST_PHP_EXECUTABLE_PATH="./vendor/bin/spin-mcp-wait.sh ./vendor/bin/spin run -T php php"
BOOST_COMPOSER_EXECUTABLE_PATH="./vendor/bin/spin run php composer"
BOOST_NPM_EXECUTABLE_PATH="./vendor/bin/spin run node npm"
```

**NEVER use `spin-mcp-wait.sh` to run commands.** It is exclusively for MCP server startup. The script will refuse non-MCP invocations with an error. Always use `spin run` or `spin exec` for running commands:

```bash
spin run php composer install          # Correct
spin run php php artisan migrate       # Correct
spin-mcp-wait.sh spin run php ...     # WRONG — never do this
```

## How Spin works

Spin wraps Docker Compose and follows its syntax exactly. Any Docker Compose option works with Spin.

The core pattern is **Docker Compose overrides**: a base `docker-compose.yml` is merged with an environment-specific override file. Spin sets `COMPOSE_FILE=docker-compose.yml:docker-compose.$SPIN_ENV.yml` automatically.

**`SPIN_ENV` defaults to `dev`**, so `spin up` is equivalent to:

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml docker compose up
```

Override with `SPIN_ENV=testing spin up` to use `docker-compose.testing.yml` instead.

The base file defines shared service structure. Override files add environment-specific settings. Docker merges them intelligently — override values replace or extend base values:

```yaml
# docker-compose.yml (base — shared across all environments)
services:
  traefik:
    image: traefik:v3.6
  php:
    depends_on:
      - traefik
```

```yaml
# docker-compose.dev.yml (development overrides)
services:
  traefik:
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./.infrastructure/conf/traefik/dev/traefik.yml:/traefik.yml:ro
  php:
    build:
      target: development
      args:
        USER_ID: ${SPIN_USER_ID}
        GROUP_ID: ${SPIN_GROUP_ID}
    volumes:
      - .:/var/www/html/
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.laravel.rule=HostRegexp(`localhost`)"
      - "traefik.http.routers.laravel.entrypoints=web"
      - "traefik.http.services.laravel.loadbalancer.server.port=8080"
      - "traefik.http.services.laravel.loadbalancer.server.scheme=http"
  node:
    image: node:22
    volumes:
      - .:/usr/src/app/
    working_dir: /usr/src/app/
```

```yaml
# docker-compose.prod.yml (production overrides — Docker Swarm)
services:
  php:
    image: ${SPIN_IMAGE_DOCKERFILE}
    environment:
      AUTORUN_ENABLED: "true"
      SSL_MODE: full
    deploy:
      replicas: 1
      update_config:
        failure_action: rollback
        order: start-first
    labels:
      - "traefik.http.routers.my-php-app.rule=Host(`${SPIN_APP_DOMAIN}`)"
      - "traefik.http.routers.my-php-app.tls.certresolver=letsencryptresolver"
```

## Project structure

```
docker-compose.yml              # Base (shared services)
docker-compose.dev.yml           # Dev overrides (ports, volumes, build target, labels)
docker-compose.prod.yml          # Prod overrides (Swarm deploy, TLS, health checks)
Dockerfile                       # Multi-stage: base → development → ci → deploy
.env                             # Read by Docker Compose AND Laravel (dual-use)
.spin.yml                        # Server inventory for provisioning (optional)
.infrastructure/
  conf/
    traefik/dev/                 # Dev Traefik config + local certs (committed)
    traefik/prod/                # Prod Traefik config (committed)
  volume_data/
    sqlite/                      # SQLite data (gitignored)
    redis/                       # Redis data (gitignored)
```

The `.infrastructure/` folder is flexible. `conf/` stores committed configuration. `volume_data/` stores gitignored persistent data for any service. This keeps everything portable — moving the project folder moves all data with it. Check the project's `.gitignore` to determine what is tracked.

## Dockerfile pattern

Multi-stage build using `serversideup/php`:

```dockerfile
FROM serversideup/php:8.5-fpm-nginx-alpine AS base
# Uncomment to add PHP extensions:
# USER root
# RUN install-php-extensions bcmath gd

FROM base AS development
ARG USER_ID
ARG GROUP_ID
USER root
RUN docker-php-serversideup-set-id www-data $USER_ID:$GROUP_ID && \
    docker-php-serversideup-set-file-permissions --owner $USER_ID:$GROUP_ID
USER www-data

FROM base AS ci
USER root

FROM base AS deploy
COPY --chown=www-data:www-data . /var/www/html
USER www-data
```

Stages: **base** (production image), **development** (matches host UID/GID via `SPIN_USER_ID`/`SPIN_GROUP_ID`), **ci** (root for CI pipelines), **deploy** (copies app code, sets permissions). The dev compose file targets the `development` stage via `build.target`.

## Development workflow

This is where 90% of Spin usage happens.

### Starting the environment

```bash
spin up --build    # Recommended: builds and starts all services (foreground)
spin up -d         # Detached mode (background)
```

`spin up` runs in the foreground — open a second terminal for other commands. Press `Ctrl+C` to stop.

### Running commands

Syntax: `spin run <service> <command>` — the first argument is the **service name** from `docker-compose.yml`.

```bash
spin run php composer install
spin run php php artisan migrate       # First "php" = service, second "php" = binary
spin run php php artisan make:model Post
spin run node yarn install
spin run node yarn dev
```

**`run` vs `exec`**: Use `spin run` for one-off commands (creates a new container, runs, exits). Use `spin exec` to execute in an already-running container (requires `spin up` to be active). Prefer `spin run` for package installs, migrations, artisan commands.

### Volume mounting

In development, the project directory is mounted at `.:/var/www/html/`, so code changes are reflected instantly — no rebuild needed for code changes.

### When to rebuild

Use `spin up --build` when:
- Starting a development environment (recommended as default habit)
- After Dockerfile changes (adding PHP extensions, changing base image)
- After modifying build-related compose settings

Code-only changes never need a rebuild — volume mounts handle it.

### `.env` dual-use

The `.env` file is read by **both** Docker Compose (for variable substitution like `${SPIN_APP_DOMAIN}`) and Laravel inside the container (since the project is volume-mounted). Example:

```env
DB_HOST=mysql
DB_DATABASE=laravel
SPIN_APP_DOMAIN=laravel.dev.test
```

### Which compose file to edit

| Change type | File |
|---|---|
| Shared service definitions (image, depends_on) | `docker-compose.yml` |
| Dev-only (ports, volume mounts, build target, Traefik labels) | `docker-compose.dev.yml` |
| Prod-only (deploy config, Swarm labels, named volumes, TLS) | `docker-compose.prod.yml` |

### Essential commands

| Command | What it does |
|---------|-------------|
| `spin up` | Start all services (`docker compose up`) |
| `spin up --build` | Start and rebuild |
| `spin down` | Stop and remove containers |
| `spin run <svc> <cmd>` | One-off command in new container |
| `spin exec <svc> <cmd>` | Command in running container |
| `spin logs` | View container logs |
| `spin ps` | List running containers |
| `spin build` | Build images without starting |

See [COMMANDS.md](COMMANDS.md) for the complete 26-command reference.

## serversideup/php images

Choose the right variant:

| Variant | Use case |
|---------|---------|
| `fpm-nginx` | Most Laravel apps (PHP-FPM + NGINX) |
| `fpm-apache` | Apps needing `.htaccess` support |
| `frankenphp` | Laravel Octane with FrankenPHP |
| `cli` | Artisan commands, queue workers, schedulers |

Tag pattern: `serversideup/php:<php-version>-<variant>[-alpine]`
Example: `serversideup/php:8.5-fpm-nginx-alpine`

Key environment variables for production:

```yaml
environment:
  AUTORUN_ENABLED: "true"           # Enable Laravel automations (migrations, caching)
  PHP_OPCACHE_ENABLE: "1"           # Enable OPcache
  SSL_MODE: "full"                  # SSL termination mode
  HEALTHCHECK_PATH: "/up"           # Laravel's built-in health route
```

See [DOCKER-IMAGES.md](DOCKER-IMAGES.md) for the full image configuration reference.

## Laravel services

In Docker, services connect via **container name as hostname**. This is critical when generating `.env` files:

```env
DB_HOST=mysql          # NOT localhost
REDIS_HOST=redis       # NOT 127.0.0.1
MAIL_HOST=mailpit
```

Available services: MySQL, PostgreSQL, MariaDB, SQLite, Redis, Laravel Queues, Horizon, Reverb, Task Scheduler, Octane, Vite, Mailpit, Meilisearch.

Avoid special characters in database passwords — use long (20+) alphanumeric passwords instead.

See [LARAVEL-SERVICES.md](LARAVEL-SERVICES.md) for complete Docker Compose configurations and `.env` settings for each service.

## Deployment

Two strategies:

### `spin deploy` (solo developers)

Builds locally, pushes via SSH tunnel, deploys to Docker Swarm — all in one command:

```bash
spin deploy production
```

Requires a provisioned server (`spin provision`) and `.spin.yml` configuration.

### GitHub Actions (teams)

Use open source actions for CI/CD:

- [`serversideup/docker-build-action`](https://github.com/marketplace/actions/docker-build-action) — Build and publish Docker images
- [`serversideup/docker-swarm-deploy-github-action`](https://github.com/marketplace/actions/docker-swarm-deploy-github-action) — Deploy to Docker Swarm

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment workflows.

## Server provisioning

`spin provision` uses Ansible to configure servers for Docker Swarm:

```bash
spin provision              # Provision all servers in .spin.yml
spin provision production   # Provision only production
```

Server requirements: Ubuntu 22.04+ LTS, x86_64, ports 22/80/443 open, fresh install.

The `.spin.yml` file defines users, providers, servers, and environments. Supports Hetzner, DigitalOcean, Vultr, or any host with SSH access.

## Common pitfalls

| Problem | Solution |
|---------|---------|
| `spin up` fails | Check Docker Desktop is running (`docker info`) |
| Missing compose file error | Ensure both `docker-compose.yml` and `docker-compose.dev.yml` exist |
| Database connection refused | Use container name as host (`DB_HOST=mysql`), not `localhost` |
| `SPIN_ENV` not set | Defaults to `dev` — set explicitly for other environments |
| Wrong image variant | Use `fpm-nginx` for web, `cli` for workers/schedulers |
| Stale containers | Use `spin up --build` to rebuild |
| DB password not working | Credentials are only created on first container init — remove volume to reset |
| Permission errors in container | Check `SPIN_USER_ID`/`SPIN_GROUP_ID` match host user |

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for remote server debugging and Docker Swarm troubleshooting.

## Reference files

| File | When to load |
|------|-------------|
| [COMMANDS.md](COMMANDS.md) | Looking up any Spin command syntax |
| [DOCKER-IMAGES.md](DOCKER-IMAGES.md) | Configuring serversideup/php images, environment variables, health checks |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Setting up deployment pipelines or running `spin deploy` |
| [LARAVEL-SERVICES.md](LARAVEL-SERVICES.md) | Adding databases, queues, Horizon, Reverb, or other Docker services |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Debugging issues on remote servers or Docker Swarm |
