#!/bin/bash
# appservice/endpoint-appservice.sh - Get App Service endpoint

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-as"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)

WEBAPP_NAME="adk-${HOSTNAME_ID}-course-creator"

echo "Retrieving endpoint for $WEBAPP_NAME..."
ENDPOINT=$(az webapp show --name "$WEBAPP_NAME" --resource-group "$AZ_RESOURCE_GROUP" --query "defaultHostName" -o tsv)

if [ -n "$ENDPOINT" ]; then
    echo "https://$ENDPOINT"
else
    echo "ERROR: Could not find endpoint. Is the app deployed?"
    exit 1
fi
