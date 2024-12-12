---
head.title: 'up | Command Reference - Spin by Server Side Up'
title: 'up'
description: 'Command reference for "spin up"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/up
---
# spin up
::lead-p
Bring up all containers defined in `compose.yaml` and `compose.$SPIN_ENV.yaml` (`$SPIN_ENV` defaults to `dev`).
::

## Usage
::code-panel
---
label: Usage for "spin up"
---
```bash
spin up [OPTIONS]
```
::

## Example
::note
If you're using a Docker Compose configuration with `build:` directives, you might want to get in the habit of using `spin up --build` to ensure you're always running the latest version of your containers.
::
::code-panel
---
label: Force a build of containers on initialization
---
```bash
spin up --build
```
::

You can add options at the end of the command (like the `--build` shown above. The above command will bring up your containers, but then also force a new build (if you have builds configured in your "compose.dev.yaml" file).

## Defaults
The `spin up` command defaults to running:
::code-panel
---
label: Command default
---
```bash
COMPOSE_FILE=compose.yaml:compose.dev.yaml docker compose up
```
::

## Official Documentation & Additional Options

#### Spin Specific Options
- `--skip-pull`: Do not automatically pull docker images.
- `--force-pull`: Pull Docker Compose images, regardless of cache settings.

### Official Docker Options
This command is a shortcut for [`docker compose up`](https://docs.docker.com/compose/reference/up/) and can accept additional options that you pass to it. It also does a number of other special things.


## Special notes
* Make sure to have a `compose.yaml` and **by default** a `compose.dev.yaml` in your project before running
* Spin will automatically pull image updates (only if the machine is connected to the Internet)
* Spin will remove any orphan containers

## Overriding the environment with `$SPIN_ENV`
Let's say you have a few different files in your repository:
::code-panel
---
label: Example project root
---
```
.
├── compose.ci.yaml
├── compose.production.yaml
├── compose.staging.yaml
├── compose.testing.yaml
└── compose.yaml
```
::


By default, Spin uses `compose.yaml` and `compose.dev.yaml`.

If you want to change that, you just need to set `$SPIN_ENV`:
::code-panel
---
label: Change spin environment
---
```bash
SPIN_ENV=testing spin up
```
::


This will essentially run:

::code-panel
---
label: Above command will execute this below
---
```bash
COMPOSE_FILE=compose.yaml:compose.testing.yaml docker compose up
```
::