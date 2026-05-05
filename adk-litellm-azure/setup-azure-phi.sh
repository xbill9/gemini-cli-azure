#!/bin/bash

# Comprehensive Setup Script for Azure AI Foundry & Phi-4-mini
# This script automates provider registration, resource creation, model deployment, and environment setup.

# 1. Configuration
RG_NAME=${RG_NAME:-"ai-foundry-rg"}
WS_NAME=${WS_NAME:-"ai-foundry-ws"}
LOCATION=${LOCATION:-"eastus"}
ENDPOINT_NAME=${ENDPOINT_NAME:-"phi-4-mini-endpoint"}
MODEL_ID="azureml://registries/azureml/models/Phi-4-mini-instruct"

echo "--- Starting Azure AI Foundry Setup ---"
echo "Resource Group: $RG_NAME"
echo "Workspace:      $WS_NAME"
echo "Location:       $LOCATION"
echo "Endpoint:       $ENDPOINT_NAME"

# 2. Ensure Azure CLI Extensions
if ! az extension show --name ml &>/dev/null; then
    echo "Installing 'ml' extension..."
    az extension add --name ml
fi

# 3. Register Resource Providers
echo "Registering necessary resource providers..."
az provider register -n Microsoft.MachineLearningServices
az provider register -n Microsoft.CognitiveServices

# Wait for registration (usually fast but can take a minute)
echo "Checking registration status..."
while [[ $(az provider show -n Microsoft.MachineLearningServices --query "registrationState" -o tsv) != "Registered" ]]; do
    echo "Waiting for Microsoft.MachineLearningServices to register..."
    sleep 10
done
echo "Microsoft.MachineLearningServices is Registered."

# 4. Create Resource Group
if ! az group show --name "$RG_NAME" &>/dev/null; then
    echo "Creating resource group $RG_NAME..."
    az group create --name "$RG_NAME" --location "$LOCATION"
else
    echo "Resource group $RG_NAME already exists."
fi

# 5. Create ML Workspace
if ! az ml workspace show --name "$WS_NAME" --resource-group "$RG_NAME" &>/dev/null; then
    echo "Creating ML workspace $WS_NAME..."
    az ml workspace create --name "$WS_NAME" --resource-group "$RG_NAME" --location "$LOCATION"
else
    echo "ML workspace $WS_NAME already exists."
fi

# 6. Create Serverless Endpoint (Phi-4-mini)
echo "Creating serverless endpoint for Phi-4-mini..."
cat <<EOF > phi-4-spec.yaml
name: $ENDPOINT_NAME
model_id: $MODEL_ID
EOF

# Note: serverless-endpoint is in preview and might fail if already exists or during provisioning
if ! az ml serverless-endpoint show --name "$ENDPOINT_NAME" --workspace-name "$WS_NAME" --resource-group "$RG_NAME" &>/dev/null; then
    az ml serverless-endpoint create -f phi-4-spec.yaml --workspace-name "$WS_NAME" --resource-group "$RG_NAME"
else
    echo "Serverless endpoint $ENDPOINT_NAME already exists."
fi
rm phi-4-spec.yaml

# 7. Retrieve Credentials
echo "Retrieving credentials..."
SCORING_URI=$(az ml serverless-endpoint show --name "$ENDPOINT_NAME" --workspace-name "$WS_NAME" --resource-group "$RG_NAME" --query "scoring_uri" -o tsv)
PRIMARY_KEY=$(az ml serverless-endpoint get-credentials --name "$ENDPOINT_NAME" --workspace-name "$WS_NAME" --resource-group "$RG_NAME" --query "primaryKey" -o tsv)

# 8. Update Environment Files
echo "Updating .env and set_env.sh..."

# Function to update or append in .env
update_env() {
    local key=$1
    local value=$2
    if grep -q "^$key=" .env 2>/dev/null; then
        sed -i "s|^$key=.*|$key=$value|" .env
    else
        echo "$key=$value" >> .env
    fi
}

touch .env
update_env "AZURE_AI_API_KEY" "$PRIMARY_KEY"
update_env "AZURE_AI_API_BASE" "$SCORING_URI"
update_env "AZURE_MODEL" "azure_ai/phi-4-mini"

# Update set_env.sh defaults
if [ -f "set_env.sh" ]; then
    sed -i "s|export AZURE_AI_API_KEY=\${AZURE_AI_API_KEY:-\".*\"}|export AZURE_AI_API_KEY=\${AZURE_AI_API_KEY:-\"$PRIMARY_KEY\"}|" set_env.sh
    sed -i "s|export AZURE_AI_API_BASE=\${AZURE_AI_API_BASE:-\".*\"}|export AZURE_AI_API_BASE=\${AZURE_AI_API_BASE:-\"$SCORING_URI\"}|" set_env.sh
    sed -i "s|export AZURE_MODEL=\${AZURE_MODEL:-\".*\"}|export AZURE_MODEL=\${AZURE_MODEL:-\"azure_ai/phi-4-mini\"}|" set_env.sh
fi

echo "--- Setup Complete! ---"
echo "Endpoint: $SCORING_URI"
echo "Model:    azure_ai/phi-4-mini"
echo "You can now run 'adk run agents/azure'"
