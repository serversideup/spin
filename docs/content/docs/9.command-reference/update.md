---
head.title: 'update | Command Reference - Spin by Server Side Up'
title: 'update'
description: 'Command reference for "spin update"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/update
---

::lead-p
Update `spin` to the latest version (on system/user installs only).
::

## Usage
```bash [Usage for "spin update"]
spin update
```

## Special notes
This will only run on machines that have `spin` installed to the system. This means if you installed `spin` via "composer" or "yarn", this command will **not** execute.

## Automatic update checks
Spin periodically asks if you'd like to check for updates. That prompt only appears in an interactive terminal, so CI pipelines, scripts, and AI coding agents are never blocked waiting for an answer.

To turn the check off entirely, set `SPIN_SKIP_UPDATE_CHECK` to `true`.

```bash [Disable automatic update checks]
export SPIN_SKIP_UPDATE_CHECK=true
```
