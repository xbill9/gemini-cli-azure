#!/bin/bash
# aca/endpoint-aca.sh - Show ACA service endpoint

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)

az containerapp show --name "adk-course-creator-${HOSTNAME_ID}" --resource-group "$AZ_RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv
