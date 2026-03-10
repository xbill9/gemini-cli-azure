# Gemini CLI Azure & Google Cloud Development

This repository contains automation scripts and configuration for cross-platform development across Microsoft Azure and Google Cloud, with a focus on various Linux distributions.

## Overview

The repository provides a set of utility scripts to streamline the setup and maintenance of development environments on Azure Linux and Debian-based systems.

## Automation Scripts

### Linux Update (`linux-update`)
Detects the OS distribution and runs the appropriate update script (`azure-update` or `debian-update`) followed by the Gemini CLI update.
```bash
./linux-update
```

### Azure Linux Update (`azure-update`)
Updates the system packages and installs essential libraries like `libatomic`.
```bash
./azure-update
```

### Debian/Ubuntu Update (`debian-update`)
Updates the system package list, upgrades existing packages, and ensures Git is installed.
```bash
./debian-update
```

### Gemini CLI Update (`gemini-update`)
Installs or updates the `@google/gemini-cli` globally using npm and verifies the installed versions of Node.js and Gemini.
```bash
./gemini-update
```

### NVM & Node.js Update (`nvm-update`)
Installs NVM (Node Version Manager) and sets up Node.js version 25.
```bash
./nvm-update
```

## Environment Requirements

- **Operating Systems:** Azure Linux, Debian, Ubuntu.
- **Tools:** Node.js, npm, Git, Azure CLI.

## Project Metadata

- **Repository:** [github.com/xbill9/gemini-cli-azure](https://github.com/xbill9/gemini-cli-azure)
- **Developer Context:** Cross-platform developer working with Microsoft Azure and Google Cloud.
