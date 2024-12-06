---
head.title: 'vault | Command Reference - Spin by Server Side Up'
title: 'vault'
description: 'Command reference for "spin vault"'
layout: docs
canonical: https://serversideup.net/open-source/spin/docs/command-reference/vault
---
# spin vault
::lead-p
Encrypt & decrypt files with "Ansible Vault". Accepts any command that [`ansible-vault`](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html) accepts.
::

## Usage
::code-panel
---
label: Usage for "spin vault"
---
```bash
spin vault <ansible-vault-action>
```
::

## Actions
The `spin vault` command will intelligently pass any arguments to your local `ansible-vault` binary or to Docker if Ansible is not installed locally. It will also accept any commands that are documented with [`ansible-vault`](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html).

### Most popular actions
- `edit`: Edit an encrypted file
- `encrypt`: Encrypt an unencrypted file
- `decrypt`: Decrypt an encrypted file

## Official Documentation & Additional Options
More actions and syntax reference can be found in the [official documentation](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html).

## Examples
::code-panel
---
label: Encrypt a file
---
```bash
spin vault encrypt myfile.txt
```
::

::code-panel
---
label: Edit an encrypted file
---
```bash
spin vault edit myfile.txt
```
::

## Special notes
This command will automatically run `ansible vault` via Docker if you do not have Ansible installed on your system. The only major downfall to this approach is when it comes to editing your secret files, you will need to do this all through `vi`, which can be pretty annoying.

If you'd like a better experience, you may want to consider installing and configuring Ansible on your local machine so you can edit your secrets with your favorite editor.

## Editing secrets with Sublime Text
It's possible to edit your secrets with Sublime Text, but it requires a bit of setup. You'll need to [install Ansible to your system](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

Once Ansible is installed and you're able to execute `ansible-vault` locally, you'll then need to set Sublime Text as your editor.

::code-panel
---
label: Set Sublime Text as your editor
---
```bash
export EDITOR="subl -w"
```
::

Add this to your `~/.bashrc` or `~/.zshrc` file to make it permanent.

## Saving the file
When you save the file with, Ansible Vault will automatically re-encrypt the file for you. You don't need to do anything else.

## Automating Vault Access
If you're constantly being asked to provide a vault password, you can speed up your workflow by securely saving your password to a `.vault-password` file in your project root.

If that file exists, Ansible will automatically load the password from that file.

::note
Never commit `.vault-password` to your repository. It should be added to your `.gitignore` file.
::