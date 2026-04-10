# Spin — Docker Workflow for Laravel

Spin is a lightweight CLI that wraps Docker Compose (development) and Docker Swarm (production) so you can replicate any environment on any machine.

## Key facts

- Spin follows Docker Compose syntax exactly — `spin up` runs `docker compose up`, `spin run` runs `docker compose run`, etc.
- Projects use a **Docker Compose overrides** pattern: a base `docker-compose.yml` merged with `docker-compose.dev.yml` (local) or `docker-compose.prod.yml` (production).
- Laravel projects use `serversideup/php` Docker images (fpm-nginx, fpm-apache, frankenphp, cli).
- The `.infrastructure/` folder stores configuration files (`conf/`) and gitignored volume data (`volume_data/`).
- `SPIN_ENV` defaults to `dev`. Running `spin up` uses `docker-compose.yml` + `docker-compose.dev.yml`.
- In Docker, services connect via container name as hostname (`DB_HOST=mysql`, `REDIS_HOST=redis`), not `localhost`.

## Essential commands

| Command | Purpose |
|---------|---------|
| `spin up` | Start development environment (foreground) |
| `spin up --build` | Start and rebuild containers (recommended default if custom Dockerfile is used) |
| `spin run <service> <cmd>` | Run a one-off command in a new container |
| `spin exec <service> <cmd>` | Run a command in a running container |
| `spin deploy <env>` | Deploy to a provisioned server |
| `spin provision` | Provision and configure servers |

## When to activate the full skill

For tasks involving Docker Compose configuration, Dockerfile changes, `serversideup/php` image settings, adding Laravel services (databases, queues, Horizon, Reverb), server provisioning, deployment, or troubleshooting containerized environments — activate the **spin-laravel-development** skill.

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
