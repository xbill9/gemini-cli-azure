#!/bin/bash
# aca/destroy-aca.sh - Delete ACA resources

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-fabric"}

echo "Destroying Azure Container Apps in $AZ_RESOURCE_GROUP..."
az containerapp delete --name course-creator --resource-group "$AZ_RESOURCE_GROUP" --yes || true

echo "Note: This does not delete the Resource Group or ACA Environment. Use az-destroy-aca to delete the whole group."
