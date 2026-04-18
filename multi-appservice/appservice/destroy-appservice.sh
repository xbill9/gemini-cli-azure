#!/bin/bash
# appservice/destroy-appservice.sh - Delete App Service resources

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-as"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)

echo "Destroying Azure App Services in $AZ_RESOURCE_GROUP..."

delete_webapp() {
    local name="adk-${HOSTNAME_ID}-$1"
    echo "Deleting $name..."
    az webapp delete --name "$name" --resource-group "$AZ_RESOURCE_GROUP" --keep-empty-plan --yes || true
}

delete_webapp "researcher"
delete_webapp "judge"
delete_webapp "content-builder"
delete_webapp "orchestrator"
delete_webapp "course-creator"

echo "Note: This does not delete the Resource Group or App Service Plan. Use az-destroy-appservice to delete the whole group."
