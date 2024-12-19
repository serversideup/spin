---
head.title: 'Migrating from Spin v2 to v3 - Spin by Server Side Up'
title: 'Migrating from Spin v2 to v3'
description: 'Learn how to migrate from Spin v2 to v3.'
layout: docs
canonical: 'https://serversideup.net/open-source/spin/docs/advanced/migrating-from-spin-v2-to-v3'
---

# Migrating from Spin v2 to v3
::lead-p
Although Spin v3 doesn't ship with any breaking changes, there is a new structure for managing your configurations with Spin that you may want to upgrade to take advantage of.
::

::note
**Spin v3 ships with zero breaking changes for Spin v2 configurations.** This means these steps are completely optional and is only required if you want to take advantage of the new features with Spin (like using native providers to provision servers on DigitalOcean, Vultr, and Hetzner)
::

## The new ".spin.yml" file
In Spin v3, we introduced a new way to manage your server inventory. Previously, we had the configurations separated across multiple files (`.spin-inventory.ini` and `.spin.yml`).

Everything has been merged into a single `.spin.yml` file. This new format gives you the ability to provision servers right from the command line with providers like DigitalOcean, Vultr, and Hetzner.

::code-panel
---
label: Example .spin.yml with v3
---
```yaml
##############################################################
# 👇 Users - You must set at least one user
##############################################################

users:
  # - username: alice
  #   name: Alice Smith
  #   groups: ['sudo']
  #   authorized_keys:
  #     - public_key: "ssh-ed25519 AAAAC3NzaC1lmyfakeublickeyMVIzwQXBzxxD9b8Erd1FKVvu alice"

  # - username: bob
  #   name: Bob Smith
  #   state: present
  #   password: "$6$mysecretsalt$qJbapG68nyRab3gxvKWPUcs2g3t0oMHSHMnSKecYNpSi3CuZm.GbBqXO8BE6EI6P1JUefhA0qvD7b5LSh./PU1"
  #   groups: ['sudo']
  #   shell: "/bin/bash"
  #   authorized_keys:
  #     - public_key: "ssh-ed25519 AAAAC3NzaC1anotherfakekeyIMVIzwQXBzxxD9b8Erd1FKVvu bob"

##############################################################
# 👇 Providers - You must set at least one provider
##############################################################

providers:
#   - name: digitalocean
#     api_token: Set token here OR delete this line and set environment variable DO_API_TOKEN

#   - name: hetzner
#     api_token: Set token here OR delete this line and set environment variable HCLOUD_TOKEN

#   - name: vultr
#     api_token: Set token here OR delete this line and set environment variable VULTR_API_KEY

##############################################################
# 👇 Servers - You must set at least one server
##############################################################

servers:
  # - server_name: ubuntu-2gb-ash-1
  #   environment: production
  #   hardware_profile: hetzner_2c_2gb_ubuntu2404

  # - server_name: ubuntu-1gb-ord-2
  #   environment: staging
  #   hardware_profile: vultr_1c_1gb_ubuntu2404

##############################################################
# 🤖 Hardware Profiles
##############################################################

hardware_profiles:
  # Hetzner
  - name: hetzner_2c_2gb_ubuntu2404
    provider: hetzner
    profile_config:
      location: ash
      server_type: cpx11
      image: ubuntu-24.04
      backups: true

  # Vultr
  - name: vultr_1c_1gb_ubuntu2404
    provider: vultr
    profile_config:
      region: ord
      plan: vc2-1c-1gb
      os: "Ubuntu 24.04 LTS x64"
      backups: true
  
  # DigitalOcean
  - name: digitalocean_1c_1gb_ubuntu2404
    provider: digitalocean
    profile_config:
      region: nyc3
      size: s-1vcpu-1gb
      image: ubuntu-24-04-x64
      backups: true

##############################################################
# 🌎 Environments
##############################################################
environments:
  - name: production
  - name: staging
  - name: development

##############################################################
# 🤓 Advanced Server Configuration
##############################################################

# Timezone and contact settings
server_timezone: "Etc/UTC"
server_contact: changeme@example.com

# If you the SSH port below, you may need to run `spin provision -p <your-default-ssh-port>`
# to get a connection on your first provision. Otherwise, SSH will try connecting 
# to your new port before the SSH server configuration is updated.
ssh_port: "22"

## You can set this to false to require a password for sudo.
## If you disable passwordless sudo, you must set a password for all sudo users.
## generate an encrypted hash with `spin mkpasswd`. Learn more:
## https://serversideup.net/open-source/spin/docs/command-reference/mkpasswd
use_passwordless_sudo: true

## Email Notifications
postfix_hostname: "{{ inventory_hostname }}"

## Set variables below to enable external SMTP relay
# postfix_relayhost: "smtp.example.com"
# postfix_relayhost_port: "587"
# postfix_relayhost_username: "myusername"
# postfix_relayhost_password: "mysupersecretpassword"

## Deploy user customization - You can customize the deploy user below if you'd like
# docker_user:
#   username: deploy
#   authorized_ssh_keys: 
#     - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNJGtd7a4DBHsQi7HGrC5xz0eAEFHZ3Ogh3FEFI2345 fake@key"
#     - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRfXxUZ8q9vHRcQZ6tLb0KwGHu8xjQHfYopZKLmnopQ anotherfake@key"
```
::

## What's changed
We changed a few things regarding this new set up:
- The `.spin-inventory.ini` is no longer configured on new projects
- The `.spin.yml` file now manages both server settings and inventory (instead of just settings before)
- On project creation, the `.spin.yml` file is no longer included in the repository by default (it acts like an `.env` file)
- On project creation, you are no longer prompted to encrypt your `.spin.yml` file (you can still do this manually)
- `use_passwordless_sudo` is now set to `true` by default, allowing sudo users to become root without a password, but they are still authenticated by their SSH key. Keep this value to `false` if you'd like to require a password for sudo.

## How to migrate a project to the new structure
You can continue to use your existing set up if you'd like, but if you want the new features, here is how you can take a Spin v2 project and set it up like a brand new Spin v3 project.

### Make a backup
This is always a good idea when you're making big changes like this. It's better to have one than not 😃. Here's where you should make backups:

- Make a copy of your local project directory
- Take a snapshot/backup of your production and staging servers
- Make sure you're on a clean branch within your project
- Plan and communicate to your users that there may be a brief interruption during the upgrade (running `spin provision` might update packages and cause 1-2 minutes of downtime)

### Ensure your .gitignore is up to date
Essentially what we want to do, is remove `.spin.yml` from the Git repository (unless if you find a certain use case to keep it in there -- as long as it's encrypted with a secure password).

::code-panel
---
label: Ensure these exist in your .gitignore
---
```
.spin*
.vault-password
```
::

### Ensure your ".env.<environment>" files are up to date
Depending how you deploy, we may be re-uploading your `.env.<environment>` files to GitHub Actions. Make sure these files are the latest and have every value accurate to what is currently running in your environments.

### Remove the ".spin-inventory.ini" file and ".spin.yml" file from the repository
We know what to remove the files from being tracked by Git.

::code-panel
---
label: Stop tracking these files in Git
---
```bash
git rm --cached .spin-inventory.ini
git rm --cached .spin.yml
```
::

### Decrypt your files so you can edit them
To make it easy for you, it's probably easiest to decrypt your files so you can easily edit them.

::code-panel
---
label: Decrypt your files
---
```bash
spin vault decrypt .spin-inventory.ini
spin vault decrypt .spin.yml
```
::

### Rename your ".spin.yml" file to ".spin.original.yml"
We just need to temporarily rename the file so we can reference it.

### Download the new ".spin.yml" file
You can copy the contents of our example file from GitHub and paste into our new `.spin.yml` file.

[View latest .spin.yml file on GitHub →](https://github.com/serversideup/ansible-collection-spin/blob/main/.spin.example.yml)

### Migrate contents from your ".spin.original.yml" file
Move any setting you'd like, but especially do not forget about these:
- `server_timezone`
- `users`
- `server_contact`
- `use_passwordless_sudo`

### Migrate the contents of your ".spin-inventory.ini" file
The other important thing is to move over our inventory from our `.spin-inventory.ini` file. To do this, let's say we have this example:

::code-panel
---
label: Example .spin-inventory.ini
---
```ini
###########################################
# 👇 Basic Server Configuration - Set your server DNS or IP address
###########################################

[production_manager_servers]
server01.example.com

[staging_manager_servers]
server02.example.com

###########################################
# 🤓 Advanced Environment Settings
###########################################
# Swarm Configuration
[swarm_managers:children]
production_manager_servers
staging_manager_servers

# Environment
[production:children]
production_manager_servers

[staging:children]
staging_manager_servers

[all_servers:children]
production
staging
```
::

The most important thing in the file is our "Basic Server Configuration" section. You can see this file has two servers, `server01.example.com` and `server02.example.com`.

We want to move them into our `.spin.yml` file, so it looks like this:

::code-panel
---
label: Example .spin.yml with migrated inventory
---
```yaml
##############################################################
# 👇 Servers - You must set at least one server
##############################################################

servers:
  - server_name: server01.example.com # ✅ You can set this to anything you want. It's just a label.
    environment: production
    # 👇 You MUST set this. Make sure it matches from your ".spin-inventory.ini" file
    address: server01.example.com
    # ❌ You can delete the line below if you're not using our native providers
    # hardware_profile: hetzner_2c_2gb_ubuntu2404

  # 👇 Here is a full example of "server02.example.com" without comments
  - server_name: server02.example.com
    environment: staging
    address: server02.example.com
```
::

### Remove the "providers" and "hardware_profiles" sections if you want
If you do not want the native providers to be used, you can remove the `providers` and `hardware_profiles` sections. As long as your server has an `address` set, Spin will use whatever host you'd like.

::note
Keep these sections if you want to use the native providers.
::

::code-panel
---
label: '❌ You can remove these lines if you want'
---
```yaml
# ##############################################################
# # 👇 Providers - You must set at least one provider
# ##############################################################

# providers:
#   - name: digitalocean
#     api_token: Set token here OR delete this line and set environment variable DO_API_TOKEN

#   - name: hetzner
#     api_token: Set token here OR delete this line and set environment variable HCLOUD_TOKEN

#   - name: vultr
#     api_token: Set token here OR delete this line and set environment variable VULTR_API_KEY

# ##############################################################
# # 🤖 Hardware Profiles
# ##############################################################

# hardware_profiles:
#   # Hetzner
#   - name: hetzner_2c_2gb_ubuntu2404
#     provider: hetzner
#     profile_config:
#       location: ash
#       server_type: cpx11
#       image: ubuntu-24.04
#       backups: true

#   # Vultr
#   - name: vultr_1c_1gb_ubuntu2404
#     provider: vultr
#     profile_config:
#       region: ord
#       plan: vc2-1c-1gb
#       os: "Ubuntu 24.04 LTS x64"
#       backups: true
  
#   # DigitalOcean
#   - name: digitalocean_1c_1gb_ubuntu2404
#     provider: digitalocean
#     profile_config:
#       region: nyc3
#       size: s-1vcpu-1gb
#       image: ubuntu-24-04-x64
#       backups: true
```
::

### Remove the v2 configuration files
Make sure to delete the old v2 files from the project when you're confident you've migrated everything.

::code-panel
---
label: Remove the files from the project
---
```bash
rm .spin-inventory.ini
rm .spin.original.yml
```
::

### Re-encrypt (if you want)
With this new set up, the `.spin.yml` file acts like an `.env` file. If you'd like the extra security, you can re-encrypt the file.

::note
If you choose TO NOT encrypt the file, be sure to delete the `.vault-password` file from your local machine.
::

::code-panel
---
label: Re-encrypt the file
---
```bash
spin vault encrypt .spin.yml
```
::

You will need a `.vault-password` file on your local machine if you intend to use the encrypted file.

### Run spin provision
If you'd like to test the new setup, you can run `spin provision` and it will use the new `.spin.yml` file.

::note
⚠️ Running `spin provision` might cause a brief interruption in your services if there is an update for Docker.
::

::code-panel
---
label: Run spin provision on your staging servers
---
```bash
spin provision staging
```
::

### Update GitHub Actions
If you're using GitHub Actions, we no longer need these environment variables. They will be reuploaded to GitHub Actions under new names when we run `spin configure gha <environment>`.

| Environment Variable | New Behavior |
| -------------------- | ------------ |
| `ENV_FILE_BASE64` | This has been renamed to `<ENVIRONMENT>_ENV_FILE_BASE64`. It will be recreated with `spin configure gha <environment>`.|
| `SSH_REMOTE_HOSTNAME` | This has been renamed to `<ENVIRONMENT>_SSH_REMOTE_HOSTNAME`. It will be recreated with `spin configure gha <environment>`. |
| `SSH_DEPLOY_PRIVATE_KEY` | You can keep this if you want. But if you do let it, we automatically create a new deploy key for you, store it under `.infrastructure/ci/SSH_DEPLOY_PRIVATE_KEY` and add it to GitHub Actions secrets. This process happens when you run `spin configure gha <environment>`. |

::note
If you added other variables such as `DB_PASSWORD` or `REDIS_PASSWORD`, you can remove those from GitHub Actions if you're confident your `.env.<environment>` files are accurate. Spin v3 will use the values from your `.env.<environment>` files to configure these services.
::

### Run "spin configure gha <environment>"
For each environment, you will need to run `spin configure gha <environment>` to update the GitHub Actions environment variables.

::code-panel
---
label: Run "spin configure gha <environment>"
---
```bash
spin configure gha staging
spin configure gha production
```
::

### Get latest Spin template
If you purchased Spin Pro, you can get the latest GitHub Actions template by reinitializing your project.

::note
The command below will delete all Dockerfiles and Spin configurations then ask you to reinitialize your project. If you made a lot of customizations to the Dockerfiles and Spin templates, you way want to manually copy the GitHub Actions template over.<br><br>
**The links below are only accessible to Spin Pro customers.**<br>
- [action_deploy-production.yml](https://github.com/serversideup/spin-template-laravel-pro/blob/main/blocks/github-actions/.github/workflows/action_deploy-production.yml)
- [service_docker-build-and-publish.yml](https://github.com/serversideup/spin-template-laravel-pro/blob/main/blocks/github-actions/.github/workflows/service_docker-build-and-publish.yml)
::

::code-panel
---
label: Reinitialize your project
---
```bash
spin init laravel-pro
```
::

## Review your pending Git changes
Now is the time to review your pending Git changes. If you're confident everything looks good, you can go ahead and commit your changes and run your deployment.

Once the deployment is complete, you're ready for Spin v3 and all the exciting new features! 🎉