---
head.title: 'down | Command Reference - Spin by Server Side Up'
title: 'down'
description: 'Command reference for "spin down"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/down
---

::lead-p
Stops containers and removes containers, networks, volumes, and images created by up.
::

## Usage
```bash [Usage for "spin down"]
spin down [OPTIONS]
```

## Official Documentation & Additional Options
This command is a shortcut for [`docker compose down`](https://docs.docker.com/compose/reference/down/){target="_blank"} and can accept additional options that you pass to it.

## Special notes
Spin automatically adds `--remove-orphans` to remove any orphan containers.