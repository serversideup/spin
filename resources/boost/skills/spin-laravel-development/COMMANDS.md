# Spin Command Reference

## Table of contents

- [Development commands](#development-commands)
- [Project setup commands](#project-setup-commands)
- [Deployment and infrastructure commands](#deployment-and-infrastructure-commands)
- [Utility commands](#utility-commands)
- [Meta commands](#meta-commands)

---

## Development commands

### `spin up`

Start all services defined in `docker-compose.yml` + `docker-compose.$SPIN_ENV.yml`.

```bash
spin up [OPTIONS]
```

Defaults to `COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml docker compose up`.

Spin-specific options:
- `--skip-pull` — Do not automatically pull images
- `--force-pull` — Pull images regardless of cache

All [`docker compose up`](https://docs.docker.com/compose/reference/up/) options are supported.

Override environment: `SPIN_ENV=testing spin up` uses `docker-compose.testing.yml`.

Tip: Use `spin up --build` when compose files have `build:` directives.

### `spin down`

Stop and remove containers, networks, volumes, and images created by `up`.

```bash
spin down [OPTIONS]
```

Wraps `docker compose down`.

### `spin stop`

Send `SIGTERM` to all containers (graceful stop).

```bash
spin stop
```

### `spin build`

Build images from compose files without starting containers.

```bash
spin build [OPTIONS]
```

Wraps [`docker compose build`](https://docs.docker.com/compose/reference/build/).

### `spin run`

Run a one-off command in a **new** container, then exit. Requires a Docker Compose file.

```bash
spin run [OPTIONS] SERVICE COMMAND
```

Examples:

```bash
spin run php composer install
spin run php php artisan migrate
spin run node yarn install
```

Spin-specific options:
- `--skip-pull` — Do not automatically pull images
- `--force-pull` — Pull images regardless of cache

The container is automatically removed after the command completes. Container dependencies are not started.

### `spin exec`

Run a command in a **currently running** container (requires `spin up` to be active).

```bash
spin exec [OPTIONS] SERVICE COMMAND
```

Example:

```bash
spin exec php php artisan tinker
```

### `spin logs`

View container logs.

```bash
spin logs [OPTIONS]
```

Wraps [`docker compose logs`](https://docs.docker.com/compose/reference/logs/). Use `-f` to follow.

### `spin ps`

List containers for the compose project.

```bash
spin ps [OPTIONS]
```

Wraps [`docker compose ps`](https://docs.docker.com/reference/cli/docker/compose/ps/).

### `spin pull`

Pull images defined in compose files.

```bash
spin pull [OPTIONS]
```

Wraps [`docker compose pull`](https://docs.docker.com/engine/reference/commandline/compose_pull/).

### `spin kill`

Send `SIGKILL` to all containers (immediate stop).

```bash
spin kill
```

---

## Project setup commands

### `spin new`

Create a new project from a template.

```bash
spin new <template-name> [project-name]
```

Available templates: `laravel`, `nuxt`, or any GitHub repo URL.

Example:

```bash
spin new laravel my-app
```

### `spin init`

Initialize Spin on an existing project. Creates Docker Compose files, Dockerfile, and `.infrastructure/` folder.

```bash
spin init [--skip-dependency-install]
```

Project types: `laravel`, `laravel-pro`, `nuxt`.

### `spin latest`

Run a one-off container with the latest PHP or Node image (works outside project directories).

```bash
spin latest SERVICE COMMAND
```

Services: `php`, `node`.

Example:

```bash
spin latest php php my_script.php
```

---

## Deployment and infrastructure commands

### `spin deploy`

Deploy application to a provisioned server. Builds locally, pushes via SSH tunnel, deploys to Docker Swarm.

```bash
spin deploy [OPTIONS] <environment>
```

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--compose-file` | `-c` | `docker-compose.yml,docker-compose.prod.yml` | Compose files to use |
| `--port` | `-p` | `22` | SSH port |
| `--user` | `-u` | Current user (`whoami`) | SSH user |
| `--upgrade` | `-U` | `false` | Force upgrade Ansible collection |

Environment variables: `SPIN_BUILD_PLATFORM` (default `linux/amd64`), `SPIN_BUILD_TAGS`, `SPIN_REGISTRY_PORT` (default `5080`), `SPIN_PROJECT_NAME`.

Per-environment `.env` files: Create `.env.production`, `.env.staging`, etc. Laravel automatically uses the correct file based on `APP_ENV`.

### `spin provision`

Provision and configure servers from `.spin.yml`.

```bash
spin provision [environment] [OPTIONS]
```

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--host` | `-h` | (none) | Target hostname or group |
| `--port` | `-p` | `22` | SSH port |
| `--user` | `-u` | Current user | SSH user |
| `--upgrade` | `-U` | Daily check | Force upgrade Ansible collection |

For non-provider servers, use `-u root` on first run.

### `spin maintain`

Apply OS and Docker updates on servers.

```bash
spin maintain [environment] [OPTIONS]
```

Same options as `spin provision`.

### `spin configure`

Configure deployment settings (GitHub Actions integration).

```bash
spin configure gha <environment>
```

Sets up GitHub Actions secrets and SSH keys for automated deployments.

---

## Utility commands

### `spin base64`

Cross-platform base64 encoding/decoding (normalizes MacOS vs Linux syntax).

```bash
spin base64 -e <file>    # Encode
spin base64 -d <file>    # Decode
```

### `spin mkpasswd`

Generate password hashes (runs `mkpasswd` via Docker).

```bash
spin mkpasswd [password]
```

Omit the password for interactive mode.

### `spin vault`

Encrypt/decrypt files with Ansible Vault.

```bash
spin vault <action> [file]
```

Actions: `edit`, `encrypt`, `decrypt`, `view`, `create`, `encrypt_string`, `rekey`.

### `spin gh`

Run GitHub CLI via Docker (`serversideup/github-cli`).

```bash
spin gh [OPTIONS] <command>
```

### `spin prune`

Clear local Docker and Spin caches. Runs `docker system prune --all`.

```bash
spin prune [OPTIONS]
```

| Option | Short | Description |
|--------|-------|-------------|
| `--force` | `-f` | Skip confirmation |

Add `--volumes` to also remove volumes.

---

## Meta commands

### `spin help`

Display a link to the Spin documentation.

```bash
spin help
```

### `spin version`

Print the installed Spin version.

```bash
spin version
```

### `spin debug`

Display environment and configuration info for bug reports.

```bash
spin debug
```

### `spin update`

Update Spin to the latest version (system installs only, not Composer/Yarn installs).

```bash
spin update
```
