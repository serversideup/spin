---
head.title: 'init | Command Reference - Spin by Server Side Up'
title: 'init'
description: 'Command reference for "spin init"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/init
---

# spin init
::lead-p
Initialize Spin on an existing project. This process will create all the files you need to get started with Spin.
::

::note
This process will create new files and may modify existing files. It's highly recommended you read through our [Add Spin to an Existing Project](/docs/getting-started/add-spin-to-an-existing-project) guide before running this command.
::

## Usage
::code-panel
---
label: Usage for "spin init"
---
```bash
spin init [--skip-dependency-install]
```
::

## What this command does
Running `spin init` will ask you a few questions about your project, then create the files you need to get started with Spin.

### Project Types:
- `laravel`: Initialize Spin into an existing Laravel project.
- `laravel-pro`: Initialize [Spin Pro's Laravel Template](https://getspin.pro) into an existing Laravel project with Laravel Pro.
- `nuxt`: Initialize Spin into an existing Nuxt project.

### Options
- `--skip-dependency-install`: Skip the installation of dependencies. This is useful if you're using a custom script to install dependencies.