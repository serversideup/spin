---
head.title: 'configure | Command Reference - Spin by Server Side Up'
title: 'configure'
description: 'Command reference for "spin configure"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/configure
---
# spin configure
::lead-p
Configure various aspects of your project's deployment settings and infrastructure.
::

## Usage
::code-panel
---
label: Usage for "spin configure"
---
```bash
spin configure <command> [options]
```
::

## Commands

### GitHub Actions (`gha`)
Configure GitHub Actions settings for deploying your application to a specific environment.

::code-panel
---
label: Configure GitHub Actions for an environment
---
```bash
spin configure gha <environment>
```
::

#### What this command does
When configuring GitHub Actions, this command:
1. Validates your project setup and GitHub repository connection
2. Creates or uses an existing deployment SSH key
3. Base64 encodes your environment file
4. Sets up required GitHub Actions secrets
5. Configures server access for deployments

#### Example
::code-panel
---
label: Configure GitHub Actions for production
---
```bash
spin configure gha production
```
::

## Prerequisites
Before running `spin configure gha`, ensure you:
- Have a GitHub repository set up (`git init` and connected to GitHub)
- Are authenticated with GitHub CLI (`spin gh auth login`)
- Have an environment file (e.g., `.env.production` for production)
- Have your server provisioned with `spin provision`

## Environment Files
The command expects an environment file matching your target environment:
- Production: `.env.production`
- Staging: `.env.staging`
- etc.

## GitHub Actions Secrets
The following environment variables are set as secrets in GitHub Actions.

| Variable | Description | Example Value | Required |
| --- | --- | --- | --- |
| `<ENVIRONMENT>_ENV_FILE_BASE64` | The base64 encoded `.env` file. | `ABCDEFG1234...` | ⚠️ Yes |
| `<ENVIRONMENT>_SSH_REMOTE_HOSTNAME` | The hostname/IP of your server. | `server01.example.com` |  ⚠️ Yes |
| `SSH_DEPLOY_PRIVATE_KEY` | The private SSH key dedicated for the deploy user. | `-----BEGIN OPENSSH PRIVATE KEY-----abc123...` | ⚠️ Yes |
| `SSH_REMOTE_KNOWN_HOSTS` | If provided, the SSH connection will validate the connection against your known_hosts file and remove the "SSH_KNOWN_HOST" warning. ([Learn more](https://github.com/serversideup/github-action-docker-swarm-deploy/?tab=readme-ov-file#removing-the-ssh_remote_known_hosts-warning)) | `github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...` | no |
| `AUTHORIZED_KEYS` | Makes an `authorized_keys` file containing the public keys of "sudo" users that can be used for authenticating other services via SSH (like database GUI connections).  | `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...` | no |

To view these environment variables in GitHub Actions, you can follow these steps:

1. Go to your GitHub repository.
2. Click on `Settings`.
3. Click on `Secrets and variables → Actions`.`

::responsive-image
---
src: /images/docs/github-actions/gha-secrets.png
alt: 'Adding a new secret to GitHub Actions'
maxWidth: 500
---
::

::note
The only way you can update a value of a secret is to overwrite the previous value. GitHub Actions does not allow you to view the value of a secret once it's set. If you need to update a value, just run `spin configure gha <environment>` again.
::

## Special Notes
- The command will create a new deployment key (under `.infrastructure/conf/ci`) if one doesn't exist
- The command will connect to your server and set the newly created deployment key as an authorized key for the docker/deploy user on your server
- All secrets are securely stored in your GitHub repository
- The command validates your setup before making any changes 