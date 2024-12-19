---
head.title: 'deploy | Command Reference - Spin by Server Side Up'
title: 'deploy'
description: 'Command reference for "spin deploy"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/deploy
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

[Learn how to prepare a server →](/docs/server-configuration/server-configuration-basics)

## Example Deployment Command
To deploy your application to the production environment, you can use the following command:

::code-panel
---
label: Deploy to Production
---
```bash
spin deploy production
```
::

To deploy to a staging environment, specify the environment name:

::code-panel
---
label: Deploy to Staging
---
```bash
spin deploy staging
```
::

You can also provide custom Docker Compose files and SSH options:

::code-panel
---
label: Custom Deployment Options
---
```bash
spin deploy staging --compose-file custom-compose.yml --user myuser --port 2222
```
::

This comprehensive process ensures that your application is built, pushed, and deployed efficiently to your server.

## Options
The following options are available to set when running this command.
| Option | Short | Default | Description |
| --- | --- | --- | --- |
| `--compose-file` | `-c` | By default, we look for two files `docker-compose.yml, docker-compose.prod.yml` | The name of the compose files. You can provide many of these options to combine many files. |
| `--port` | `-p` | `22` | The port to SSH into the server with. |
| `--upgrade` | `-U` | `false` | Force the upgrade of the Ansible collection. |
| `--user` | `-u` | The username of your HOST machine (run `whoami` in a new terminal) | The user to SSH into the server with. |

## Change Options with Environment Variables
You can also modify the behavior of the `spin deploy` command by setting environment variables:

| Environment Variable | Default | Description |
| --- | --- | --- |
| `SPIN_BUILD_PLATFORM` | `linux/amd64` | The platform to build the Docker image with. |
| `SPIN_BUILD_TAGS` | `latest` | The tags to use when building the Docker image. |
| `SPIN_INVENTORY_FILE` | `/etc/ansible/collections/ansible_collections/serversideup/spin/plugins/inventory/spin-dynamic-inventory.sh` | The inventory file or dynamic inventory script to use for the deployment. |
| `SPIN_PROJECT_NAME` | `spin` | The name of the project to use for the deployment. |
| `SPIN_REGISTRY_PORT` | `5080` | The port to use on your local machine for the temporary registry. |
| `SPIN_TRAEFIK_CONFIG_FILE` | `./.infrastructure/conf/traefik/prod/traefik.yml` | The Traefik configuration file to use for the deployment. |

## Environment Variables Available For Compose Files
The following environment variables are available to use in your compose files after running this command.

| Variable | Example  | Description  |
| --- | --- | --- |
| `SPIN_IMAGE_*`              | `localhost:5080/dockerfile:latest` or `localhost:5080/dockerfile.php:latest`    | Automatically generated for each Dockerfile in the project directory. The variable name is derived from the Dockerfile name (e.g., `SPIN_IMAGE_DOCKERFILE` derives from `Dockerfile`, `SPIN_IMAGE_DOCKERFILE_PHP` derives from `Dockerfile.php`), and the value contains the full image name including registry, image name (based on Dockerfile name), and tag. These variables can be used in Docker Compose files to reference the built images. |
| `SPIN_MD5_HASH_*` | `abcdef123456`                        | The MD5 Hash value of all configs under `.infrastructure/conf`. For example, `.infrastructure/conf/traefik/dev/traefik.yml`'s MD5 value will be stored in `SPIN_MD5_HASH_TRAEFIK_YML`|
| `SPIN_DEPLOYMENT_ENVIRONMENT` | `production`                         | The environment you are deploying to.|
| Anything from your `.env` file | `DB_PASSWORD`                         | Any environment variables you have set in your `.env` file.|
| `SPIN_APP_DOMAIN` | `example.com`                         | This variable is created from `APP_URL` and extracts the app domain. This is helpful for frameworks like Laravel when we load up the `.env` file.|

## Using different `.env` files per environment
By default, everything runs off the `.env` file. This is great for local development, but it can be a challenge if you want to deploy to multiple environments from the same folder.

To solve this, you can create `.env` files for each environment you want to deploy to. For example, you can create `.env.production` and `.env.staging` files. When you run `spin deploy production`, the `.env.production` file will be used. When you run `spin deploy staging`, the `.env.staging` file will be used.

::note
This approach is highly reliant on the framework you're using. For example, when you run `spin deploy production`, the `APP_ENV` variable will be set to `production`. [Laravel is intelligent enough](https://laravel.com/docs/11.x/configuration#additional-environment-files) to know to use the `.env.production` file. If you're using a different framework, you might need to adjust your configuration to use this approach.
::

Be sure to add `.env.*` files to your `.gitignore` file so they are not committed to your repository.

## What happens when you run `spin deploy`?

Running the `spin deploy` command automates the process of deploying your application to your server. Here's a breakdown of the steps it performs:

### Loads Environment Variables
If a `.env` file exists in your project directory, the script loads the environment variables defined in it.

### Sets Default Values
The script sets default values for various deployment parameters, which can be overridden by environment variables:
- `SPIN_REGISTRY_PORT`: Port for the local Docker registry (default is 5080).
- `SPIN_BUILD_PLATFORM`: Platform for building the Docker image (default is "linux/amd64").
- `SPIN_BUILD_IMAGE_PREFIX`: Prefix for the Docker image name (default is "localhost:<registry_port>").
- `SPIN_BUILD_TAG`: Tag for the Docker image (default is "latest").
- `SPIN_INVENTORY_FILE`: Path to the Ansible inventory file or dynamic inventory script (default is "/etc/ansible/collections/ansible_collections/serversideup/spin/plugins/inventory/spin-dynamic-inventory.sh").
- `SPIN_SSH_PORT`: SSH port for connecting to the server.
- `SPIN_SSH_USER`: SSH user for connecting to the server (default is "deploy").
- `SPIN_PROJECT_NAME`: Name of the project (default is "spin").

### Checks for Dockerfiles
If Dockerfiles are found in the current directory, the script performs the following steps:
- Starts a local Docker registry if one is not already running.
- Builds a Docker image using `docker buildx`, tagging it with the appropriate name and platform.
- Pushes the built Docker image to the local registry.

### Sets Up SSH Tunnel
The script establishes an SSH tunnel to the Docker registry on the target server to facilitate secure communication.

### Deploys the Docker Stack
The script uses Docker Compose to deploy the Docker stack on the target server, utilizing the specified Docker Compose files. It validates the deployment by checking the exit status of the Docker command.

### Cleans Up
The script cleans up by stopping the local Docker registry and terminating the SSH tunnel.