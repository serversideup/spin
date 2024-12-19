---
head.title: 'provision | Command Reference - Spin by Server Side Up'
title: 'provision'
description: 'Command reference for "spin provision"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/provision
---
# spin provision
::lead-p
Provision and set up your inventory of servers. Before running this command, make sure you have everything configured and a supported server online with any host of your choice.
::

## Usage
::code-panel
---
label: Usage for "spin provision"
---
```bash
spin provision [environment] [ -p|--port <port> -u|--user <user> -U|--upgrade ]
```
::

::note
If you're not using our native provider integration, you may need to add `-u root` to the command when you first run it. This will use the `root` user to connect and configure your other users. See our guide on [Using Any Host](/docs/providers/use-any-host) for more details.
::

## Checklist before executing this command
Before you execute this command, you should have the following completed:

- Your [`.spin.yml` file](/docs/server-configuration/server-configuration-basics) should be configured
- You have at least one provider API token set **OR** you have a server with the `address` property set
- If you're using your own server (not through a provider), make sure you have `-u root` set in the command (or whatever your host's default sudo user is)
- If you're using a server with the `address` property, make sure you have SSH access to the server and it meets our [server requirements](/docs/server-configuration/server-requirements)

## What happens when you run this command?
You can learn more [how servers work with Spin](/docs/server-configuration/server-configuration-basics#how-servers-work-with-spin) but depending on your set up, below shows what will happen when you run this command:

### If you have a provider API token set
- Create your server(s) with your host
- Update your `.spin.yml` file with the actual IP address of the server that was just created
- Update your server to the latest Linux packages
- Configure the provider's firewall to only allow SSH and HTTP/S traffic and apply it to your server
- Configure your system users for server access
- Harden and secure your server against common attacks
- Install and configure Docker Swarm for zero-downtime deployments

### If you have a server with the `address` property set
- Connect to your server using SSH
- Update your server to the latest Linux packages
- Configure your system users for server access
- Harden and secure your server against common attacks
- Install and configure Docker Swarm for zero-downtime deployments

## Options
The following options are available to set when running this command.
| Option | Short | Default | Description |
| --- | --- | --- | --- |
| `environment` | - | `all` | Optional. The target environment to provision (e.g., `production`, `staging`). |
| `--host` | `-h` | <none> | The hostname or group of hosts you'd like to provision. |
| `--port` | `-p` | `22` | The port to SSH into the server with. |
| `--user` | `-u` | The username of your HOST machine (run `whoami` in a new terminal) | The user to SSH into the server with. |
| `--upgrade` | `-U` | Check for Ansible collection updates once per day. | Force upgrade the Ansible Collection on your machine before provisioning. |

## Learn More
[Configuring your servers for "spin provision" →](/docs/server-configuration/server-configuration-basics)