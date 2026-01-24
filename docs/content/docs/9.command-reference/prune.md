---
head.title: 'prune | Command Reference - Spin by Server Side Up'
title: 'prune'
description: 'Command reference for "spin prune"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/prune
---

::lead-p
Clear the local Docker and Spin caches on your machine.
::

## Usage
```bash [Usage for "spin prune"]
spin prune [OPTIONS]
```

## Options
The following options are available to set when running this command.
| Option | Short | Default | Description |
| --- | --- | --- | --- |
| `--force` | `-f` | `false` | Force the deletion of the local Docker and Spin caches. |

## Official Documentation & Additional Options
This command is a shortcut for [`docker system prune --all`](https://docs.docker.com/engine/reference/commandline/system_prune/) and can accept additional options that you pass to it. Spin defaults the `--all` for you already, so no need to add that.

If you want to clear volumes as well, you will need to add `--volumes` to the end of the command.

```bash [Clear volumes as well as all other containers.]
spin prune --volumes
```