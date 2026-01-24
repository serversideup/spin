---
head.title: 'exec | Command Reference - Spin by Server Side Up'
title: 'exec'
description: 'Command reference for "spin exec"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/exec
---

::lead-p
Use `exec` if you want to run a command in **currently running** containers.
::

## Usage
```bash [Usage for "spin exec"]
spin exec [OPTIONS] SERVICE COMMAND
```

## Example
```bash [Example of running `php artisan migrate` within the `php` container]
spin exec php php artisan migrate
```

The above command runs `php artisan migrate` inside of the `php` service (this is why "php" is repeated twice).

## Special notes
This will only run on machines that have `spin` installed on it. This means if you installed `spin` via "composer" or "yarn", this command will **not** execute.