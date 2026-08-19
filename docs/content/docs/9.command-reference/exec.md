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
```bash [Example of running "php artisan migrate" within the "php" container]
spin exec php php artisan migrate
```

The above command runs `php artisan migrate` inside of the `php` service (this is why "php" is repeated twice).

## Official Documentation & Additional Options
This command is a shortcut for [`docker compose exec`](https://docs.docker.com/compose/reference/exec/){target="_blank"} and can accept additional options that you pass to it.

## Special notes
This command requires the containers to already be running (start them with `spin up`). If your containers are not running, use [`spin run`](/docs/command-reference/run) instead.