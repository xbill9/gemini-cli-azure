#!/bin/bash

# Azure AI Foundry Settings
export AZURE_AI_API_KEY=${AZURE_AI_API_KEY}
export AZURE_AI_API_BASE=${AZURE_AI_API_BASE:-"https://phi-4-mini-endpoint.eastus.models.ai.azure.com"}
export AZURE_MODEL=${AZURE_MODEL:-"azure_ai/phi-4-mini"}

cat <<EOF > .env
AZURE_AI_API_KEY=$AZURE_AI_API_KEY
AZURE_AI_API_BASE=$AZURE_AI_API_BASE
AZURE_MODEL=$AZURE_MODEL
EOF

echo "Sourcing Env"
source .env

echo "Current Environment"
cat .env

echo "ADK Version"
adk --version
