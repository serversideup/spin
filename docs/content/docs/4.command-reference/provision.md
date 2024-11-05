---
head.title: 'provision | Command Reference - Spin by Server Side Up'
title: 'provision'
description: 'Command reference for "spin provision"'
layout: docs
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
spin provision [ -p|--port <port> -u|--user <user> -U|--upgrade ]
```
::

## Checklist before executing this command
Before you execute this command, you should have the following completed:

- You should have a running **Ubuntu 22.04+ server** with properly configured SSH access
- The `.spin.yml` file should be configured 

## Options
The following options are available to set when running this command.
| Option | Short | Default | Description |
| --- | --- | --- | --- |
| `--host` | `-h` | <none> | The hostname or group of hosts you'd like to provision. |
| `--port` | `-p` | `22` | The port to SSH into the server with. |
| `--user` | `-u` | The username of your HOST machine (run `whoami` in a new terminal) | The user to SSH into the server with. |
| `--upgrade` | `-U` | Check for Ansible collection updates once per day. | Force upgrade the Ansible Collection on your machine before provisioning. |

## Learn More
[Configuring your servers for "spin provision" →](/docs/getting-started/preparing-your-servers-for-spin)