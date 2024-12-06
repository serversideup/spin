---
head.title: 'new | Command Reference - Spin by Server Side Up'
title: 'new'
description: 'Command reference for "spin new"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/new
---
# spin new
::lead-p
Create and initialize a new project with Spin.
::

## Usage
::code-panel
---
label: Usage for "spin new"
---
```txt
spin new <template-name> <project-name>
```
::

::note
`<template-name>` can either be an "official template" provided by the Spin team, or any GitHub repository in the format of `username/repo`.
::

## Create a new project with Spin installed
Getting started with a new project is easy with Spin. Simply run the `spin new` command followed by your project name and Spin will create a new project for you with Spin installed.

## Official Spin Template running Laravel
We only have one official template right now, but we're working to add more templates. This Laravel template that will get you up and running with the latest stable version of Laravel with the default configurations running SQLite.

#### Repository
- [serversideup/spin-template-laravel-basic](https://github.com/serversideup/spin-template-laravel-basic)

#### Usage

::code-panel
---
label: Usage for "spin new"
---
```txt
spin new laravel
```
::

### Optional - Specify your project name
By default, Spin will use the framework's default project name and create the project in the current directory of where you're running Spin. If you'd like to specify your own project name, simply add it as the second argument to the `spin new` command.

::code-panel
---
label: Example of "spin new" with custom project name
---
```bash
spin new laravel my-billion-dollar-idea
```