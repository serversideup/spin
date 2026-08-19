---
head.title: 'Stop | Command Reference - Spin by Server Side Up'
title: 'stop'
description: 'Command reference for "spin stop"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/stop
---

::lead-p
Send a `SIGTERM` to **all running containers on your machine** (not just your project's containers), then after a grace period, send `SIGKILL`. Read more on the official [docker stop](https://docs.docker.com/engine/reference/commandline/stop/){target="_blank"} documentation.
::

## Usage
```bash [Usage for "spin stop"]
spin stop
```

## Special notes
- This command runs `docker stop` directly (not `docker compose stop`), so it affects **every running container on your machine** and does not accept any options.
- You will be prompted to confirm before anything is stopped. Because of this prompt, avoid using `spin stop` in scripts, CI, or other non-interactive contexts — it will hang waiting for input.
- If you only want to stop your current project's containers, use [`spin down`](/docs/command-reference/down) instead.