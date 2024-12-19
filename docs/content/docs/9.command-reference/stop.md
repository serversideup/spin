---
head.title: 'Stop | Command Reference - Spin by Server Side Up'
title: 'stop'
description: 'Command reference for "spin stop"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/stop
---
# spin stop
::lead-p
Send a `SIGTERM` to **all containers**, then after a grace period, send `SIGKILL`. Read more on the official [docker stop](https://docs.docker.com/engine/reference/commandline/stop/) documentation.
::

## Usage
::code-panel
---
label: Usage for "spin stop"
---
```bash
spin stop
```
::