#!/bin/bash
# aci/destroy-aci.sh - Destroy ACI resources

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aci"}

echo "Destroying ACI container groups in $AZ_RESOURCE_GROUP..."

containers=("researcher" "judge" "content-builder" "orchestrator" "course-creator")

for container in "${containers[@]}"; do
    echo "Deleting $container..."
    az container delete --name "$container" --resource-group "$AZ_RESOURCE_GROUP" --yes || true
done

echo "ACI containers destroyed."
