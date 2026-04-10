# Deployment

## Table of contents

- [Choosing a strategy](#choosing-a-strategy)
- [spin deploy](#spin-deploy)
- [GitHub Actions](#github-actions)
- [Production compose patterns](#production-compose-patterns)
- [Per-environment env files](#per-environment-env-files)
- [spin.yml server configuration](#spinyml-server-configuration)

---

## Choosing a strategy

| Strategy | Best for | Complexity |
|----------|----------|------------|
| `spin deploy` | Solo developers, simple deployments | Low |
| GitHub Actions | Teams, CI/CD pipelines | Medium |

Both strategies deploy to Docker Swarm with zero-downtime updates.

## spin deploy

Builds locally, pushes via SSH tunnel to the server, deploys as a Docker Swarm stack — all in one command:

```bash
spin deploy production
spin deploy staging
```

### How it works

1. Loads `.env` (or `.env.<environment>`)
2. Finds Dockerfiles and builds images with `docker buildx`
3. Starts a temporary local Docker registry
4. Pushes built images to the local registry
5. Opens an SSH tunnel to the server
6. Server pulls images through the tunnel
7. Deploys the Docker Swarm stack
8. Cleans up registry and tunnel

### Prerequisites

- Server provisioned with `spin provision`
- `.spin.yml` configured with server addresses
- SSH access to the server

### Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--compose-file` | `-c` | `docker-compose.yml,docker-compose.prod.yml` | Compose files |
| `--port` | `-p` | `22` | SSH port |
| `--user` | `-u` | Current user | SSH user |
| `--upgrade` | `-U` | `false` | Force Ansible collection upgrade |

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SPIN_BUILD_PLATFORM` | `linux/amd64` | Build platform |
| `SPIN_BUILD_TAGS` | `latest` | Image tags |
| `SPIN_REGISTRY_PORT` | `5080` | Local registry port |
| `SPIN_PROJECT_NAME` | `spin` | Project name for the stack |
| `SPIN_TRAEFIK_CONFIG_FILE` | `.infrastructure/conf/traefik/prod/traefik.yml` | Traefik config path |

### Compose variables available after deploy

| Variable | Example | Description |
|----------|---------|-------------|
| `SPIN_IMAGE_DOCKERFILE` | `localhost:5080/dockerfile:latest` | Built image reference |
| `SPIN_MD5_HASH_*` | `abcdef123456` | MD5 of config files (for Swarm config rotation) |
| `SPIN_DEPLOYMENT_ENVIRONMENT` | `production` | Target environment name |
| `SPIN_APP_DOMAIN` | `example.com` | Extracted from `APP_URL` in `.env` |

## GitHub Actions

Open source actions for automated CI/CD:

- [**docker-build-action**](https://github.com/marketplace/actions/docker-build-action) — Build and publish Docker images
- [**docker-swarm-deploy-github-action**](https://github.com/marketplace/actions/docker-swarm-deploy-github-action) — Deploy to Docker Swarm

### Setup with Spin

```bash
spin configure gha <environment>
```

This configures GitHub repository secrets and SSH keys for deployment.

### Security considerations

- Deployment SSH keys are stored in GitHub Actions secrets
- Consider self-hosted runners for tighter security
- Consider IP-restricted SSH access for production servers

### Zero-downtime requirements

For zero-downtime deployments to work:
- Traefik (or another reverse proxy) must be configured
- Container health checks must be defined
- Docker Swarm update configs must use `order: start-first`
- Services must handle graceful shutdown

## Production compose patterns

Key settings for `docker-compose.prod.yml`:

```yaml
services:
  php:
    image: ${SPIN_IMAGE_DOCKERFILE}
    environment:
      PHP_OPCACHE_ENABLE: "1"
      AUTORUN_ENABLED: "true"
      SSL_MODE: full
      HEALTHCHECK_PATH: "/up"
    deploy:
      replicas: 1
      update_config:
        failure_action: rollback
        parallelism: 1
        delay: 5s
        order: start-first
      rollback_config:
        parallelism: 0
        order: stop-first
      restart_policy:
        condition: any
        delay: 10s
        max_attempts: 3
        window: 120s
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`${SPIN_APP_DOMAIN}`)"
      - "traefik.http.routers.app.entrypoints=websecure"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.routers.app.tls.certresolver=letsencryptresolver"
      - "traefik.http.services.app.loadbalancer.server.port=8443"
      - "traefik.http.services.app.loadbalancer.server.scheme=https"
      - "traefik.http.services.app.loadbalancer.healthcheck.path=/up"
      - "traefik.http.services.app.loadbalancer.healthcheck.interval=30s"
      - "traefik.http.services.app.loadbalancer.healthcheck.scheme=http"

  traefik:
    configs:
      - source: traefik
        target: /etc/traefik/traefik.yml

configs:
  traefik:
    name: "traefik-${SPIN_MD5_HASH_TRAEFIK_YML}.yml"
    file: ./.infrastructure/conf/traefik/prod/traefik.yml

volumes:
  storage_private:
  storage_public:
  storage_sessions:
  storage_logs:
  database_sqlite:

networks:
  web-public:
```

## Per-environment env files

Create separate `.env` files for each deployment environment:

```
.env                # Local development (default)
.env.production     # Production settings
.env.staging        # Staging settings
```

`spin deploy production` sets `APP_ENV=production`, and Laravel automatically loads `.env.production`.

Add `.env.*` to `.gitignore`.

## .spin.yml server configuration

The `.spin.yml` file defines your server inventory. Basic structure:

```yaml
users:
  - username: alice
    name: Alice
    groups: ["sudo"]
    authorized_ssh_keys:
      - "ssh-ed25519 AAAA... alice@example.com"

servers:
  - server_name: server01
    environment: production
    address: 203.0.113.10

environments:
  production:
    docker_user: alice
```

For provider-managed servers (Hetzner, DigitalOcean, Vultr), Spin creates the server and fills in the `address` automatically.

Encrypt sensitive values with `spin vault encrypt .spin.yml`.
