#!/bin/bash
# aca/status-aca.sh - Check status of Azure Container Apps

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}

echo "Checking Azure Container Apps status in $AZ_RESOURCE_GROUP..."
az containerapp list --resource-group "$AZ_RESOURCE_GROUP" --query "[].{Name:name, State:properties.provisioningState, FQDN:properties.configuration.ingress.fqdn}" -o table
