---
head.title: 'run | Command Reference - Spin by Server Side Up'
title: 'run'
description: 'Command reference for "spin run"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/run
---
# spin run
::lead-p
Use `run` if you want to run a command with NEW containers. This is helpful for package installers, etc. This command does require a Docker Compose file to run. If you're looking for a command that you can run in any directory, check out [`spin latest`](/docs/command-reference/latest/).
::

## Usage
::code-panel
---
label: Usage for "spin run"
---
```bash
spin run [OPTIONS] SERVICE COMMAND 
```
::

## Example
::code-panel
---
label: Example of running a container for "composer install" with PHP
---
```bash
spin run php composer install
```
::

#### Spin Specific Options
- `--skip-pull`: Do not automatically pull docker images.
- `--force-pull`: Pull Docker Compose images, regardless of cache settings.

### Official Docker Options
This command is a shortcut for [`docker-compose run`](https://docs.docker.com/compose/reference/run/) and can accept additional options that you pass to it.

## Special notes
* This command specifically ignores running container dependencies
* It will automatically remove the containers once the command is complete
* It adds extra environment variables to improve user-experience if you're running things like "S6 Overlay" inside your containers