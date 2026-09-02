---
head.title: 'run | Command Reference - Spin by Server Side Up'
title: 'run'
description: 'Command reference for "spin run"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/run
---

::lead-p
Use `run` if you want to run a command with NEW containers. This is helpful for package installers, etc. This command does require a Docker Compose file to run. If you're looking for a command that you can run in any directory, check out [`spin latest`](/docs/command-reference/latest/).
::

## Usage
```bash [Usage for "spin run"]
spin run [OPTIONS] SERVICE COMMAND 
```

## Example
```bash [Example of running a container for "composer install" with PHP]
spin run php composer install
```

```bash [Example of running a test suite that needs the database running]
spin run --with-deps php php artisan test
```

#### Spin Specific Options
- `--skip-pull`: Do not automatically pull docker images.
- `--force-pull`: Pull Docker Compose images, regardless of cache settings.
- `--with-deps`: Start the service's dependencies (anything listed under `depends_on`) instead of skipping them.

### Official Docker Options
This command is a shortcut for [`docker-compose run`](https://docs.docker.com/compose/reference/run/){target="_blank"} and can accept additional options that you pass to it.

## Special notes
* This command ignores container dependencies by default to keep one-off commands fast. Pass `--with-deps` when your command needs the rest of the stack, like a test suite that requires a database.
* It will automatically remove the containers once the command is complete
* It adds extra environment variables to improve user-experience if you're running things like "S6 Overlay" inside your containers