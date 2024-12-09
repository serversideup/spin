---
head.title: 'maintain | Command Reference - Spin by Server Side Up'
title: 'maintain'
description: 'Command reference for "spin maintain"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/maintain
---
# spin maintain
::lead-p
Apply updates to your inventory of servers.
::

## Usage
::note
When you perform maintenance on your server, your server may experience brief downtime if it the updates require a reboot. Be sure to run this command during a communicated maintenance window.
::

::code-panel
---
label: Usage for "spin maintain"
---
```bash
spin maintain [environment] [ -p|--port <port> -u|--user <user> -U|--upgrade ]
```
::

![Spin Maintain Command](/images/docs/whats-spin/spin-maintain.png)

## Checklist before executing this command
Before you execute this command, you should have the following completed:

- You should have a running **Ubuntu 22.04+ server** with properly configured SSH access
- The `.spin.yml` file should be configured

## What this command does
The above command will:

- Connect to your server(s)
- Update the all operating system packages
- Update Docker
- Reboot the server (if needed)

## Options
The following options are available to set when running this command.
| Option | Short | Default | Description |
| --- | --- | --- | --- |
| `environment` | - | `all` | Optional. The target environment to maintain (e.g., `production`, `staging`). |
| `--host` | `-h` | <none> | The hostname or group of hosts you'd like to apply updates to. |
| `--port` | `-p` | `22` | The port to SSH into the server with. |
| `--user` | `-u` | The username of your HOST machine (run `whoami` in a new terminal) | The user to SSH into the server with. |
| `--upgrade` | `-U` | Check for Ansible collection updates once per day. | Force upgrade the Ansible Collection on your machine before applying updates. |