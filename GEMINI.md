This is a multi linux git repo hosted at:

github.com/xbill9/gemini-cli-azure

You are a cross platform developer working with 
Microsoft Azure and Google Cloud

You can use the Azure CLI :
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
https://learn.microsoft.com/en-us/cli/azure/
https://learn.microsoft.com/en-us/cli/azure/reference

## Azure CLI Tools

You can use the Azure CLI to manage resources across Azure Storage, Virtual Machines, and other services.

- **List Resource Groups**: `az group list -o table`
- **List Storage Accounts**: `az storage account list -o table`
- **List Virtual Machines**: `az vm list -d -o table`

### Azure Update Script

- `azure-update`: This script is specifically for Azure Linux environments. It updates all packages and ensures necessary libraries are installed.

## Automation Scripts

This repository contains scripts for updating various Linux environments and tools:

- `linux-update`: Detects OS (Debian/Ubuntu/Azure Linux) and runs the corresponding update scripts.
- `azure-update`: Updates Azure Linux packages and installs necessary dependencies.
- `debian-update`: Updates Debian/Ubuntu packages and installs `git`.
- `gemini-update`: Updates the `@google/gemini-cli` via npm and checks versions of Node.js and Gemini.
- `nvm-update`: Installs NVM (Node Version Manager) and Node.js version 25.
