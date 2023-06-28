---
head.title: 'Stop | Command Reference - Spin by Server Side Up'
title: 'Stop'
description: 'Command reference for "spin stop"'
layout: docs
---
## Stop
Send a `SIGTERM` to **all containers**, then after a grace period, send `SIGKILL`. Read more on the official [docker stop](https://docs.docker.com/engine/reference/commandline/stop/) documentation.

## Usage
::code-panel
---
label: Usage for "spin stop"
---
```bash
spin stop
```
::