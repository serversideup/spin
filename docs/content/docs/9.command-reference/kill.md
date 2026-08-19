---
head.title: 'kill | Command Reference - Spin by Server Side Up'
title: 'kill'
description: 'Command reference for "spin kill"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/kill
---

::lead-p
Send `SIGKILL` to **all running containers on your machine** (not just your project's containers). See the documentation on [docker kill](https://docs.docker.com/engine/reference/commandline/kill/){target="_blank"} for more advanced usage.
::

## Usage
```bash [Usage for "spin kill"]
spin kill
```

## Special notes
- This command runs `docker kill` directly (not `docker compose kill`), so it affects **every running container on your machine** and does not accept any options.
- You will be prompted to confirm before anything is killed. Because of this prompt, avoid using `spin kill` in scripts, CI, or other non-interactive contexts — it will hang waiting for input.
- If you only want to stop your current project's containers, use [`spin stop`](/docs/command-reference/stop) or [`spin down`](/docs/command-reference/down) instead.