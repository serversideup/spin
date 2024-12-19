---
head.title: 'base64 | Command Reference - Spin by Server Side Up'
title: 'base64'
description: 'Command reference for "spin base64"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/base64
---
# spin base64
::lead-p
Encode and decode strings with base64.
::

## Usage
::code-panel
---
label: Usage for "spin build"
---
```bash
spin base64 [OPTIONS] <file>
```
::

### Options
- `encode` (or `-e`): Encode a string with base64
- `decode` (or `-d`): Decode a string with base64

## Examples
::code-panel
---
label: Encode a file with base64
---
```bash
spin base64 -e myfile.txt
```
::

::code-panel
---
label: Decode a file with base64
---
```bash
spin base64 decode myfile.txt
```
::

## Special notes
This command runs the `base64` command on your system, but it standardizes the syntax between Linux and macOS. This means you can use this command on both systems without having to remember the different syntax.