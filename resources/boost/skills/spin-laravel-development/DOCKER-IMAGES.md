# serversideup/php Docker Images

## Table of contents

- [Image variants](#image-variants)
- [Tag format](#tag-format)
- [Key environment variables](#key-environment-variables)
- [Laravel automations](#laravel-automations)
- [Health checks](#health-checks)
- [Adding PHP extensions](#adding-php-extensions)
- [S6 Overlay](#s6-overlay)

---

## Image variants

| Variant | Process model | Use case |
|---------|--------------|----------|
| `fpm-nginx` | NGINX + PHP-FPM (S6 Overlay) | Most Laravel web apps |
| `fpm-apache` | Apache + PHP-FPM (S6 Overlay) | Apps needing `.htaccess` |
| `frankenphp` | FrankenPHP/Caddy | Laravel Octane, HTTP/2+3 |
| `fpm` | PHP-FPM only | Bring your own web server |
| `cli` | CLI only | Artisan, queue workers, schedulers, CI |

## Tag format

```
serversideup/php:<php-version>-<variant>[-alpine]
```

Examples:

```
serversideup/php:8.5-fpm-nginx
serversideup/php:8.5-fpm-nginx-alpine
serversideup/php:8.4-frankenphp
serversideup/php:8.5-cli
```

Images are available on Docker Hub and GitHub Packages. Debian by default, Alpine available.

## Key environment variables

### PHP configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MEMORY_LIMIT` | `256M` | PHP memory limit |
| `PHP_MAX_EXECUTION_TIME` | `99` | Max execution time (seconds) |
| `PHP_UPLOAD_MAX_FILE_SIZE` | `256M` | Max upload file size |
| `PHP_POST_MAX_SIZE` | `256M` | Max POST size |
| `PHP_OPCACHE_ENABLE` | `0` | Enable OPcache (`1` for production) |
| `PHP_DATE_TIMEZONE` | `UTC` | PHP timezone |

### Application

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_BASE_DIR` | `/var/www/html` | Application base directory |
| `LOG_OUTPUT_LEVEL` | `warn` | Container log verbosity (`debug`, `info`, `warn`, `off`) |
| `DISABLE_DEFAULT_CONFIG` | (unset) | Disable all default configs and automations |
| `SHOW_WELCOME_MESSAGE` | `true` | Show startup welcome message |

### SSL (fpm-nginx, fpm-apache)

| Variable | Default | Description |
|----------|---------|-------------|
| `SSL_MODE` | `off` | SSL mode (`off`, `full`) |
| `SSL_CERTIFICATE_FILE` | (default path) | Path to SSL certificate |
| `SSL_PRIVATE_KEY_FILE` | (default path) | Path to SSL private key |

### NGINX (fpm-nginx only)

| Variable | Default | Description |
|----------|---------|-------------|
| `NGINX_WEBROOT` | `/var/www/html/public` | NGINX document root |
| `NGINX_CLIENT_MAX_BODY_SIZE` | `256M` | Max request body size |

### S6 Overlay (fpm-nginx, fpm-apache only)

| Variable | Default | Description |
|----------|---------|-------------|
| `S6_BEHAVIOUR_IF_STAGE2_FAILS` | `2` | `2` = stop container on failure |
| `S6_CMD_WAIT_FOR_SERVICES_MAXTIME` | (default) | Max wait for services (ms) |

## Laravel automations

All automations require `AUTORUN_ENABLED=true`. Enable in **production only** — set `false` in CI.

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTORUN_ENABLED` | `false` | Master switch for all automations |
| `AUTORUN_LARAVEL_OPTIMIZE` | `true` | Run `php artisan optimize` |
| `AUTORUN_LARAVEL_CONFIG_CACHE` | `true` | Cache configuration |
| `AUTORUN_LARAVEL_EVENT_CACHE` | `true` | Cache events |
| `AUTORUN_LARAVEL_ROUTE_CACHE` | `true` | Cache routes |
| `AUTORUN_LARAVEL_VIEW_CACHE` | `true` | Cache views |
| `AUTORUN_LARAVEL_STORAGE_LINK` | `true` | Create storage symlink |
| `AUTORUN_LARAVEL_MIGRATION` | `true` | Run migrations |
| `AUTORUN_LARAVEL_MIGRATION_FORCE` | `true` | Use `--force` flag |
| `AUTORUN_LARAVEL_MIGRATION_ISOLATION` | `false` | Use `--isolated` (needs shared cache driver) |
| `AUTORUN_LARAVEL_MIGRATION_TIMEOUT` | `30` | Seconds to wait for DB before migrating |

On startup, automations clear config cache, wait for the database (retrying every second up to `MIGRATION_TIMEOUT`), then run migrations and caching. If any step fails, the container does not start.

## Health checks

| Variable | Default | Variants |
|----------|---------|----------|
| `HEALTHCHECK_PATH` | `/healthcheck` | fpm-nginx, fpm-apache |

For Laravel, use the built-in health route:

```yaml
environment:
  HEALTHCHECK_PATH: "/up"
```

In production with Traefik, configure both Docker health checks and Traefik health checks:

```yaml
labels:
  - "traefik.http.services.app.loadbalancer.healthcheck.path=/up"
  - "traefik.http.services.app.loadbalancer.healthcheck.interval=30s"
  - "traefik.http.services.app.loadbalancer.healthcheck.scheme=http"
```

## Adding PHP extensions

Use `install-php-extensions` in the Dockerfile:

```dockerfile
FROM serversideup/php:8.5-fpm-nginx-alpine AS base
USER root
RUN install-php-extensions bcmath gd intl redis
```

Always switch to `USER root` before installing, then back to `USER www-data` in subsequent stages.

## S6 Overlay

Used by `fpm-nginx` and `fpm-apache` to run two processes (web server + PHP-FPM) in one container. Handles startup ordering: user setup, Laravel automations, then the main process.

Not used by `frankenphp` (single process) or `cli` (no web server).

## Full documentation

- Docs: <https://serversideup.net/open-source/docker-php/docs>
- LLM-friendly: <https://serversideup.net/open-source/docker-php/llms.txt>
- LLM-friendly (full): <https://serversideup.net/open-source/docker-php/llms-full.txt>
- Complete environment variable reference: <https://serversideup.net/open-source/docker-php/docs/reference/environment-variable-specification>
