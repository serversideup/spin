---
head.title: 'latest | Command Reference - Spin by Server Side Up'
title: 'latest'
description: 'Command reference for "spin latest"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/latest
---
# spin latest
::lead-p
Run a one-off container to perform a task with the latest version of the container type you specify. This is great when you need to run composer or npm commands outside of a project directory.
::

## Usage
::code-panel
---
label: Usage for "spin latest"
---
```bash
spin latest [OPTIONS] SERVICE COMMAND 
```
::

### Options
- `php`: Run the latest stable version of PHP
- `node`: Run the latest stable LTS version of Node

## Example
::code-panel
---
label: Example of running a container for "composer install" with PHP
---
```bash
spin latest php php my_script.php
```
::

The above command will run the latest stable version of `php`, then run the command `php my_script.php` inside the container. The `php` in the command is duplicated because one is the service name name of `php` and the other is the command to run `php` inside the container.