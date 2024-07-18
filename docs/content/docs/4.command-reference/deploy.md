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

| Variable | Example  | Description  |
| --- | --- | --- |
| `SPIN_IMAGE_NAME`              | `localhost:5080/dockerfile:latest`    | The environment you are deploying to.|
| `SPIN_MD5_HASH_*` | `abcdef123456`                        | The MD5 Hash value of all configs under `.infrastructure/conf`. For example, `.infrastructure/conf/traefik/dev/traefik.yml`'s MD5 value will be stored in `SPIN_MD5_HASH_TRAEFIK_YML`|
| Anything from your `.env` file | `DB_PASSWORD`                         | Any environment variables you have set in your `.env` file.x|

## What happens when you run `spin deploy`?

Running the `spin deploy` command automates the process of deploying your application to your server. Here's a breakdown of the steps it performs:

### 1. Loading Environment Variables
If a `.env` file exists in your project directory, the script loads the environment variables defined in it.

### 2. Setting Default Values
The script sets default values for various deployment parameters, which can be overridden by environment variables:
- `SPIN_REGISTRY_PORT`: Port for the local Docker registry (default is 5080).
- `SPIN_BUILD_PLATFORM`: Platform for building the Docker image (default is "linux/amd64").
- `SPIN_BUILD_IMAGE_PREFIX`: Prefix for the Docker image name (default is "localhost:<registry_port>").
- `SPIN_BUILD_TAG`: Tag for the Docker image (default is "latest").
- `SPIN_INVENTORY_FILE`: Path to the Ansible inventory file (default is "/ansible/.spin-inventory.ini").
- `SPIN_SSH_PORT`: SSH port for connecting to the server.
- `SPIN_SSH_USER`: SSH user for connecting to the server (default is "deploy").
- `SPIN_PROJECT_NAME`: Name of the project (default is "spin").

### 3. Cleaning Up
The script sets a trap to ensure that the local Docker registry is stopped when the script exits.

### 4. Processing Command-Line Arguments
You can customize the deployment using the following command-line options:
- `-u, --user`: Specify the SSH user (default is "deploy").
- `-c, --compose-file`: Specify custom Docker Compose files.
- `-p, --port`: Specify the SSH port.

### 5. Validating the Environment
The script ensures that a deployment environment is specified, defaulting to "production" if none is provided.

### 6. Checking for Dockerfiles
If Dockerfiles are found in the current directory, the script performs the following steps:
- Starts a local Docker registry if one is not already running.
- Builds a Docker image using `docker buildx`, tagging it with the appropriate name and platform.
- Pushes the built Docker image to the local registry.

### 7. Setting Up an SSH Tunnel
The script establishes an SSH tunnel to the Docker registry on the target server to facilitate secure communication.

### 8. Deploying the Docker Stack
The script uses Docker Compose to deploy the Docker stack on the target server, utilizing the specified Docker Compose files. It validates the deployment by checking the exit status of the Docker command.