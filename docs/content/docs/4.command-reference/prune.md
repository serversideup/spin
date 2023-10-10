---
head.title: 'prune | Command Reference - Spin by Server Side Up'
title: 'prune'
description: 'Command reference for "spin prune"'
layout: docs
---
## Prune
Clear the local Docker cache on your machine.

## Usage
::code-panel
---
label: Usage for "spin prune"
---
```bash
spin prune [OPTIONS]
```
::

## Official Documentation & Additional Options
This command is a shortcut for [`docker system prune --all`](https://docs.docker.com/engine/reference/commandline/system_prune/) and can accept additional options that you pass to it. Spin defaults the `--all` for you already, so no need to add that.

If you want to clear volumes as well, you will need to add `--volumes` to the end of the command.

::code-panel
---
label: Clear volumes as well as all other containers.
---
```bash
spin prune --volumes
```
::