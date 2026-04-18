#!/bin/bash
# aci/status-aci.sh - Check status of Azure Container Instances

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aci"}

echo "Checking Azure Container Instances status in $AZ_RESOURCE_GROUP..."
az container list --resource-group "$AZ_RESOURCE_GROUP" --query "[].{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" -o table
