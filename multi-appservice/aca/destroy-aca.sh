#!/bin/bash
# aca/destroy-aca.sh - Delete ACA resources

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}

echo "Destroying Azure Resource Group $AZ_RESOURCE_GROUP..."
az group delete --name "$AZ_RESOURCE_GROUP" --yes --no-wait
echo "Resource Group deletion initiated."
