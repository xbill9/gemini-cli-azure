#!/bin/bash
# aca/endpoint-aca.sh - Get public URL for Course Creator on ACA

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-fabric"}

echo "--- Azure ACA Endpoint ---"
FQDN=$(az containerapp show --name course-creator --resource-group "$AZ_RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null)
if [ -z "$FQDN" ]; then
    echo "Pending or not found..."
else
    echo "https://$FQDN"
fi
