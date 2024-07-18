---
head.title: 'deploy | Command Reference - Spin by Server Side Up'
title: 'deploy'
description: 'Command reference for "spin deploy"'
layout: docs
---
# spin deploy
::lead-p
Quickly and easily deploy your application to a server without the hassle of setting up CI/CD pipelines. Before running this command, make sure you have everything configured and a supported server online with any host of your choice.
::

## Usage
::code-panel
---
label: Usage for "spin deploy"
---
```bash
spin deploy [ -c|--compose-file <compose-file> -p|--port <port> -u|--user <user> ] <environment>
```
::

## Before getting started
Be sure you have "provisioned" your server before running this command. If you haven't, you can do so by running `spin provision` before running `spin deploy`.

[Learn how to prepare a server →](/docs/guide/preparing-your-servers-for-spin)

## Options
The following options are available to set when running this command.
| Option | Short | Default | Description |
| --- | --- | --- | --- |
| `--compose-file` | `-c` | By default, we look for two files `docker-compose.yml, docker-compose.prod.yml` | The name of the compose files. You can provide many of these options to combine many files. |
| `--port` | `-p` | `22` | The port to SSH into the server with. |
| `--user` | `-u` | The username of your HOST machine (run `whoami` in a new terminal) | The user to SSH into the server with. |

## Change Options with Environment Variables
You can also modify the behavior of the `spin deploy` command by setting environment variables:

| Environment Variable | Default | Description |
| --- | --- | --- |
| `SPIN_BUILD_PLATFORM` | `linux/amd64` | The platform to build the Docker image with. |
| `SPIN_BUILD_TAGS` | `latest` | The tags to use when building the Docker image. |
| `SPIN_INVENTORY_FILE` | `.spin-inventory.ini` | The inventory file to use for the deployment. |
| `SPIN_PROJECT_NAME` | `spin` | The name of the project to use for the deployment. |
| `SPIN_REGISTRY_PORT` | `5080` | The port to use on your local machine for the temporary registry. |
| `SPIN_TRAEFIK_CONFIG_FILE` | `./.infrastructure/conf/traefik/prod/traefik.yml` | The Traefik configuration file to use for the deployment. |

## Environment Variables Available For Compose Files
The following environment variables are available to use in your compose files after running this command.

| Variable | Example | Description |
| --- | --- | --- |
| `SPIN_IMAGE_NAME` | `localhost:5080/dockerfile:latest` | The environment you are deploying to. |
| `SPIN_TRAEFIK_CONFIG_MD5_HASH` | `abcdef123456` | The MD5 hash value of the contents of the Traefik configuration (if it exists). This is helpful for setting Docker Swarm configurations and that it should only kill the Traefik service if there is an update to the config. |