---
head.title: 'down | Command Reference - Spin by Server Side Up'
title: 'down'
description: 'Command reference for "spin down"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/down
---
# spin down
::lead-p
Stops containers and removes containers, networks, volumes, and images created by up.
::

## Usage
::code-panel
---
label: Usage for "spin down"
---
```bash
spin down [OPTIONS]
```
::

## Special notes
This will only run on machines that have `spin` installed on it. This means if you installed `spin` via "composer" or "yarn", this command will **not** execute.