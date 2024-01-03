---
head.title: 'new | Command Reference - Spin by Server Side Up'
title: 'new'
description: 'Command reference for "spin new"'
layout: docs
---
# spin new
::lead-p
Create and initialize a new project with Spin.
::

## Usage
::code-panel
---
label: Usage for "spin build"
---
```bash
spin new <app-type> <project-name>
```
::
## Create a new project with Spin installed
Getting started with a new project is easy with Spin. Simply run the `spin new` command followed by your project name and Spin will create a new project for you with Spin installed.

### Project Types:
- `laravel`: Create a new project with the latest stable version of Laravel.
- `nuxt`: Create a new project with the latest stable version of Nuxt.

### Optional - Specify your project name
By default, Spin will use the framework's default project name and create the project in the current directory of where you're running Spin. If you'd like to specify your own project name, simply add it as the second argument to the `spin new` command.

::code-panel
---
label: Example of "spin new" with custom project name
---
```bash
spin new laravel my-billion-dollar-idea
```