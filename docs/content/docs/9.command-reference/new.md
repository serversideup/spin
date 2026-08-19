---
head.title: 'new | Command Reference - Spin by Server Side Up'
title: 'new'
description: 'Command reference for "spin new"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/new
---

::lead-p
Create and initialize a new project with Spin.
::

## Usage
```txt [Usage for "spin new"]
spin new <template-name> <project-name>
```

::note
`<template-name>` can either be an "official template" provided by the Spin team, or any GitHub repository in the format of `username/repo`.
::

## Create a new project with Spin installed
Getting started with a new project is easy with Spin. Simply run the `spin new` command followed by your project name and Spin will create a new project for you with Spin installed.

## Official Spin Templates
The following official templates are available:

| Template | Repository | Description |
| --- | --- | --- |
| `laravel` | [serversideup/spin-template-laravel-basic](https://github.com/serversideup/spin-template-laravel-basic){target="_blank"} | The latest stable version of Laravel with the default configurations running SQLite. |
| `laravel-pro` | [Spin Pro](https://getspin.pro){target="_blank"} | Premium Laravel template with pre-configured services (databases, Horizon, Reverb, Vite, Mailpit, and more). |
| `nuxt` | [serversideup/spin-template-nuxt](https://github.com/serversideup/spin-template-nuxt){target="_blank"} | The latest stable version of Nuxt. |
| `skeleton` | [serversideup/spin-template-skeleton](https://github.com/serversideup/spin-template-skeleton){target="_blank"} | A bare-bones starting point for building your own template. |

You can also pass any GitHub repository in the format of `username/repo` to use a community template.

#### Usage

```txt [Usage for "spin new"]
spin new laravel
```

### Optional - Specify your project name
By default, Spin will use the framework's default project name and create the project in the current directory of where you're running Spin. If you'd like to specify your own project name, simply add it as the second argument to the `spin new` command.

::code-panel
---
label: Example of "spin new" with custom project name
---
```bash
spin new laravel my-billion-dollar-idea
```