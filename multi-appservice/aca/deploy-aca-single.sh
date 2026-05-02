#!/bin/bash
# aca/deploy-aca-single.sh - Deploy the all-in-one container to Azure Container Apps (ACA)

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
# Append a short random string for better uniqueness
RANDOM_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}${RANDOM_ID}"}
AZ_ACA_ENV=${AZ_ACA_ENV:-"adk-env-${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"v$(date +%Y%m%d%H%M%S)"}
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/all-in-one:${IMAGE_TAG}"

echo "=== Azure Container Apps Single Container Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "ACA Environment: $AZ_ACA_ENV"
echo "============================="

# 1. Create Resource Group
echo "Ensuring Resource Group exists..."
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table

# 2. Create ACR
echo "Ensuring ACR exists..."
if ! az acr show --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az acr create --resource-group "$AZ_RESOURCE_GROUP" --name "$AZ_ACR_NAME" --sku Basic --admin-enabled true -o table
fi
az acr login --name "$AZ_ACR_NAME"

ACR_USER=$(az acr credential show --name "$AZ_ACR_NAME" --query "username" -o tsv)
ACR_PASS=$(az acr credential show --name "$AZ_ACR_NAME" --query "passwords[0].value" -o tsv)

# 3. Build and Push All-in-One Image
echo "Building all-in-one image..."
docker build -t "$FULL_IMAGE_NAME" -f single-container/Dockerfile .

echo "Pushing image to ACR..."
docker push "$FULL_IMAGE_NAME"

# 4. Create ACA Environment
echo "Ensuring ACA Environment exists..."
if ! az containerapp env show --name "$AZ_ACA_ENV" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az containerapp env create \
        --name "$AZ_ACA_ENV" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" -o table
fi

# 5. Deploy Container App
CA_NAME="adk-all-in-one-${HOSTNAME_ID}"
echo "Deploying $CA_NAME to ACA..."

if ! az containerapp show --name "$CA_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az containerapp create \
        --name "$CA_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --environment "$AZ_ACA_ENV" \
        --image "$FULL_IMAGE_NAME" \
        --target-port 8080 \
        --ingress external \
        --registry-server "$ACR_LOGIN_SERVER" \
        --registry-username "$ACR_USER" \
        --registry-password "$ACR_PASS" \
        --env-vars GOOGLE_API_KEY="$GEMINI_API_KEY" BYPASS_AUTH=true AGENT_NAME="orchestrator" \
        --query "properties.configuration.ingress.fqdn" -o tsv
else
    az containerapp update \
        --name "$CA_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --image "$FULL_IMAGE_NAME" \
        --set-env-vars GOOGLE_API_KEY="$GEMINI_API_KEY" BYPASS_AUTH=true AGENT_NAME="orchestrator" \
        --query "properties.configuration.ingress.fqdn" -o tsv
fi

echo "=== Deployment Complete ==="
echo "App URL: https://$(az containerapp show --name "$CA_NAME" --resource-group "$AZ_RESOURCE_GROUP" --query properties.configuration.ingress.fqdn -o tsv)"
