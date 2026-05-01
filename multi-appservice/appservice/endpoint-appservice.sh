#!/bin/bash
# appservice/endpoint-appservice.sh - Get App Service endpoint

set -e

AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-as"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)

# Try to find the "full" consolidated app first, then fallback to course-creator
FULL_WEBAPP="adk-${HOSTNAME_ID}-full"
CC_WEBAPP="adk-${HOSTNAME_ID}-course-creator"

echo "Retrieving endpoint for $FULL_WEBAPP or $CC_WEBAPP..."
ENDPOINT=$(az webapp show --name "$FULL_WEBAPP" --resource-group "$AZ_RESOURCE_GROUP" --query "defaultHostName" -o tsv 2>/dev/null || \
           az webapp show --name "$CC_WEBAPP" --resource-group "$AZ_RESOURCE_GROUP" --query "defaultHostName" -o tsv 2>/dev/null)

if [ -n "$ENDPOINT" ]; then
    echo "https://$ENDPOINT"
else
    echo "ERROR: Could not find endpoint. Is the app deployed?"
    exit 1
fi
