# Troubleshooting

## Table of contents

- [Local development issues](#local-development-issues)
- [Docker Swarm debugging](#docker-swarm-debugging)
- [Exec into running containers](#exec-into-running-containers)
- [Viewing application logs](#viewing-application-logs)
- [Health check debugging](#health-check-debugging)
- [Database connection issues](#database-connection-issues)
- [Full reset](#full-reset)
- [Re-provisioning a server](#re-provisioning-a-server)

---

## Local development issues

| Symptom | Cause | Solution |
|---------|-------|---------|
| Spin command fails to run | Docker Desktop not started | Run `docker info` to verify. Start Docker Desktop, then retry. |
| Missing compose file error | No `docker-compose.dev.yml` | Create the file or set `SPIN_ENV` to match your override file name |
| Port already in use | Another service on port 80/443 | Stop the conflicting service or change ports in `docker-compose.dev.yml` |
| Permission denied in container | UID/GID mismatch | Check `SPIN_USER_ID` and `SPIN_GROUP_ID` match host user (`id -u`, `id -g`) |
| Stale containers / old image | Cached Docker layers | Run `spin up --build` to rebuild |
| Container exits immediately | Error in entrypoint | Check `spin logs` for the error message |

---

## Docker Swarm debugging

These commands run on the **remote server** (SSH in first).

### List all services

```bash
sudo docker service ls
```

### View service logs

```bash
sudo docker service logs <service_name>
sudo docker service logs -f <service_name>    # Follow logs
```

### View service task history

Shows why containers failed to start:

```bash
sudo docker service ps --no-trunc <service_name>
```

### Inspect service configuration

```bash
sudo docker service inspect <service_name> --pretty
```

---

## Exec into running containers

Find the container ID and exec in:

```bash
sudo docker exec -it $(sudo docker ps --filter "name=<service_name>" --format "{{.ID}}" | head -n 1) sh
```

Or step by step:

```bash
sudo docker ps                                # Find the container ID
sudo docker exec -it <container_id> sh        # Open a shell
```

---

## Viewing application logs

### Laravel logs inside a container

```bash
sudo docker exec -it <container_id> sh
cat storage/logs/laravel.log
```

### Enable debug-level container output

Set `LOG_OUTPUT_LEVEL=debug` on `serversideup/php` images for verbose container output.

### Application-level logging

For production, use external services (Sentry, GlitchTip, etc.) — container logs are ephemeral and can be lost on restarts.

---

## Health check debugging

Two types of health checks can fail independently:

### Docker health checks

Defined in the Dockerfile or compose file. Docker uses these to determine container health.

### Traefik health checks

Defined in Traefik labels. Traefik uses these to route traffic.

### Common misconfigurations

| Issue | Symptom | Fix |
|-------|---------|-----|
| Wrong health check path | Container unhealthy | Set `HEALTHCHECK_PATH="/up"` |
| Wrong port in Traefik label | 502 Bad Gateway | Match `loadbalancer.server.port` to container's listening port |
| Wrong scheme | Connection refused | Use `scheme=http` for internal checks, even if TLS terminates at Traefik |
| Typo in domain variable | Traefik returns 404 | Check `SPIN_APP_DOMAIN` in `.env` matches DNS |

---

## Database connection issues

| Issue | Solution |
|-------|---------|
| Connection refused | Use container name as host (`DB_HOST=mysql`), not `localhost` |
| Access denied | Credentials only created on first `docker volume create`. Remove volume and restart to reset. |
| Special characters in password | Use long alphanumeric passwords without special characters |
| DB not ready at startup | `AUTORUN_LARAVEL_MIGRATION_TIMEOUT` controls wait time (default 30s) |

---

## Full reset

Remove everything on a remote server and start fresh:

```bash
# Remove all services
sudo docker service rm $(sudo docker service ls -q)

# Remove all containers
sudo docker rm -f $(sudo docker ps -aq)

# Remove all volumes (DESTRUCTIVE — data loss)
sudo docker volume rm $(sudo docker volume ls -q)

# Remove all configs
sudo docker config rm $(sudo docker config ls -q)

# System prune
sudo docker system prune --all --force
```

Then redeploy with `spin deploy <environment>`.

---

## Re-provisioning a server

To re-provision a server from scratch:

1. Remove the `address` field from the server in `.spin.yml` (if using a provider, this triggers a new server)
2. Clear the old SSH key: `ssh-keygen -R <old-ip-address>`
3. Run `spin provision <environment>`

For existing servers with a new IP, update the `address` in `.spin.yml` and clear the old SSH fingerprint before provisioning.
