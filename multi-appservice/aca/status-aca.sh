#!/bin/bash
# aca/status-aca.sh - Show ACA status

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}

echo "=== Azure Container Apps Status ==="
az containerapp list --resource-group "$AZ_RESOURCE_GROUP" --query "[].{Name:name, Status:properties.provisioningState, FQDN:properties.configuration.ingress.fqdn}" -o table
