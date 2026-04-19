#!/bin/bash
# aci/endpoint-aci.sh - Get public URL for Course Creator on ACI

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aci"}

echo "--- Azure ACI Endpoint ---"
FQDN=$(az container show --name course-creator-group --resource-group "$AZ_RESOURCE_GROUP" --query "ipAddress.fqdn" -o tsv 2>/dev/null)
if [ -z "$FQDN" ]; then
    echo "Pending or not found..."
else
    echo "http://$FQDN:8080"
fi
