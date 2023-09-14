---
head.title: 'run | Command Reference - Spin by Server Side Up'
title: 'run'
description: 'Command reference for "spin run"'
layout: docs
---
## Run
Use `run` if you want to run a command with NEW containers. This is helpful for package installers, etc.

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
- `--no-pull`: Do not automatically pull docker images.

### Official Docker Options
This command is a shortcut for [`docker-compose run`](https://docs.docker.com/compose/reference/run/) and can accept additional options that you pass to it.

## Special notes
* This command specifically ignores running container dependencies
* It will automatically remove the containers once the command is complete
* It adds extra environment variables to improve user-experience if you're running things like "S6 Overlay" inside your containers