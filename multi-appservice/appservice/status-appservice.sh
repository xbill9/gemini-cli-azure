#!/bin/bash
# appservice/status-appservice.sh - Check App Service status

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-as"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)

echo "=== Azure App Service Status ==="
echo "Resource Group: $AZ_RESOURCE_GROUP"

show_status() {
    local name="adk-${HOSTNAME_ID}-$1"
    echo "--- $name ---"
    az webapp show --name "$name" --resource-group "$AZ_RESOURCE_GROUP" --query "{State:state, HostNames:enabledHostNames[0]}" -o table || echo "Not found"
}

show_status "researcher"
show_status "judge"
show_status "content-builder"
show_status "orchestrator"
show_status "course-creator"
