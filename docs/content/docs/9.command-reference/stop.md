---
head.title: 'Stop | Command Reference - Spin by Server Side Up'
title: 'stop'
description: 'Command reference for "spin stop"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/stop
---

::lead-p
Gracefully stop your project's running containers without removing them. Containers can be started again with `spin up`.
::

## Usage
```bash [Usage for "spin stop"]
spin stop [OPTIONS] [SERVICE...]
```

## Example
```bash [Stop all project services]
spin stop
```

```bash [Stop a single service]
spin stop php
```

## Official Documentation & Additional Options
This command is a shortcut for [`docker compose stop`](https://docs.docker.com/compose/reference/stop/){target="_blank"} and can accept additional options that you pass to it.

## Special notes
- Unlike [`spin down`](/docs/command-reference/down), this keeps your containers and networks in place — it only stops the processes.
- If you need to immediately kill **every container on your machine** (not just this project), see [`spin kill`](/docs/command-reference/kill).
