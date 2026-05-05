#!/bin/bash

# This script attempts to find your Azure AI Foundry Phi-4-mini credentials
# and set them as environment variables.

# 1. Ensure the ML extension is installed
if ! az extension show --name ml &>/dev/null; then
    echo "Installing 'ml' extension..."
    az extension add --name ml
fi

# 2. Find the Resource Group and Workspace (Project)
# We look for the first workspace that likely contains our deployment
WORKSPACE_INFO=$(az ml workspace list --query "[0].{rg:resourceGroup, name:name}" -o json)
RG=$(echo $WORKSPACE_INFO | jq -r '.rg')
WS=$(echo $WORKSPACE_INFO | jq -r '.name')

if [ "$WS" == "null" ] || [ -z "$WS" ]; then
    echo "Error: No Azure AI Foundry project (ML Workspace) found."
fi

echo "Found Project: $WS in Resource Group: $RG"

# 3. Find the Endpoint
# We look for an endpoint that contains 'phi-4' in the name
ENDPOINT_NAME=$(az ml serverless-endpoint list --workspace-name "$WS" --resource-group "$RG" --query "[?contains(name, 'phi-4')].name | [0]" -o tsv)

if [ -z "$ENDPOINT_NAME" ] || [ "$ENDPOINT_NAME" == "None" ]; then
    echo "Error: Could not find a serverless endpoint containing 'phi-4'."
    echo "Available serverless endpoints:"
    az ml serverless-endpoint list --workspace-name "$WS" --resource-group "$RG" --query "[].name" -o table
    exit 1
fi

echo "Found Endpoint: $ENDPOINT_NAME"

# 4. Get the URL and Key
ENDPOINT_URL=$(az ml serverless-endpoint show --name "$ENDPOINT_NAME" --workspace-name "$WS" --resource-group "$RG" --query "scoring_uri" -o tsv)
# LiteLLM azure_ai/ prefix usually expects the base URL without the path
AZURE_AI_API_BASE=$(echo "$ENDPOINT_URL" | sed 's/\/score//')

AZURE_AI_API_KEY=$(az ml serverless-endpoint get-credentials --name "$ENDPOINT_NAME" --workspace-name "$WS" --resource-group "$RG" --query "primaryKey" -o tsv)

# 5. Export and Update .env
export AZURE_AI_API_KEY=$AZURE_AI_API_KEY
export AZURE_AI_API_BASE=$AZURE_AI_API_BASE

echo "Successfully retrieved credentials!"
echo "AZURE_AI_API_BASE: $AZURE_AI_API_BASE"
echo "AZURE_AI_API_KEY: [HIDDEN]"

# Update the local .env file
if [ -f "set_env.sh" ]; then
    source ./set_env.sh
else
    echo "AZURE_AI_API_KEY=$AZURE_AI_API_KEY" >> .env
    echo "AZURE_AI_API_BASE=$AZURE_AI_API_BASE" >> .env
fi
