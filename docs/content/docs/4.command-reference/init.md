---
head.title: 'init | Command Reference - Spin by Server Side Up'
title: 'init'
description: 'Command reference for "spin init"'
layout: docs
---

# spin init
::lead-p
Initialize Spin on an existing project. This process will create all the files you need to get started with Spin.
::

::note
This process will create new files and may modify existing files. It's highly recommended you read through our [Add Spin to an Existing Project](/docs/guide/add-spin-to-an-existing-project) guide before running this command.
::

## Usage
::code-panel
---
label: Usage for "spin init"
---
```bash
spin init
```
::

## What this command does
Running `spin init` will ask you a few questions about your project, then create the files you need to get started with Spin.

### Project Types:
- `laravel`: Initialize Spin into an existing Laravel project.
- `nuxt`: Initialize Spin into an existing Nuxt project.