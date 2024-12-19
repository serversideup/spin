---
head.title: 'mkpasswd | Command Reference - Spin by Server Side Up'
title: 'mkpasswd'
description: 'Command reference for "spin mkpasswd"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/mkpasswd
---
# spin mkpasswd
::lead-p
Generate a password hash using the mkpasswd utility.
::

## Usage
::code-panel
---
label: Usage for "spin mkpasswd"
---
```bash
spin mkpasswd [OPTIONS]
```
::

## Official Documentation & Additional Options
This command is a shortcut for running [`mkpasswd`](https://linux.die.net/man/1/mkpasswd) with Docker. This is helpful for generating temporary password hashes when configuring your `.spin.yml` file.

## Examples
::code-panel
---
label: Generate a password hash
---
```bash
spin mkpasswd mypassword
```
::

You can also use "interactive mode" by being prompted to enter a password. This is helpful if you don't want to expose the password in your terminal history.

::code-panel
---
label: Generate a password hash interactively
---
```bash
spin mkpasswd
```