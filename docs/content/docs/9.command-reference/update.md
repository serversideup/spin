---
head.title: 'update | Command Reference - Spin by Server Side Up'
title: 'update'
description: 'Command reference for "spin update"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/update
---
# spin update
::lead-p
Update `spin` to the latest version (on system/user installs only).
::

## Usage
::code-panel
---
label: Usage for "spin update"
---
```bash
spin update
```
::

## Special notes
This will only run on machines that have `spin` installed to the system. This means if you installed `spin` via "composer" or "yarn", this command will **not** execute.