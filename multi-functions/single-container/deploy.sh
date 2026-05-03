#!/bin/bash
# single-container/deploy.sh - Deploy the all-in-one container to Azure Functions

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-functions"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
RANDOM_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}${RANDOM_ID}"}
AZ_STORAGE_NAME=${AZ_STORAGE_NAME:-"adkstorage${HOSTNAME_ID}${RANDOM_ID}"}
AZ_APP_PLAN_NAME=${AZ_APP_PLAN_NAME:-"adk-plan-${HOSTNAME_ID}"}
FUNCTION_APP_NAME="adk-${HOSTNAME_ID}-func"
IMAGE_TAG="v$(date +%Y%m%d%H%M%S)"
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/all-in-one:${IMAGE_TAG}"

echo "=== Azure Functions All-in-One Deployment ==="
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "Storage Name:   $AZ_STORAGE_NAME"
echo "Function Name:  $FUNCTION_APP_NAME"
echo "============================="

# 1. Create Resource Group
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table

# 2. Create Storage Account (Required for Functions)
if ! az storage account show --name "$AZ_STORAGE_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az storage account create \
        --name "$AZ_STORAGE_NAME" \
        --location "$AZ_LOCATION" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --sku Standard_LRS -o table
fi

# 3. Create/Get ACR
if ! az acr show --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az acr create --resource-group "$AZ_RESOURCE_GROUP" --name "$AZ_ACR_NAME" --sku Basic --admin-enabled true -o table
fi
az acr login --name "$AZ_ACR_NAME"

ACR_USER=$(az acr credential show --name "$AZ_ACR_NAME" --query "username" -o tsv)
ACR_PASS=$(az acr credential show --name "$AZ_ACR_NAME" --query "passwords[0].value" -o tsv)

# 4. Build and Push All-in-One Image
echo "Building all-in-one image..."
docker build -t "$FULL_IMAGE_NAME" -f single-container/Dockerfile .

echo "Pushing image to ACR..."
docker push "$FULL_IMAGE_NAME"

# 5. Create Azure App Service Plan (Premium or Dedicated for Containers)
if ! az functionapp plan show --name "$AZ_APP_PLAN_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az functionapp plan create \
        --name "$AZ_APP_PLAN_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" \
        --is-linux \
        --sku EP1 -o table
fi

# 6. Create Function App
if ! az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az functionapp create \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --storage-account "$AZ_STORAGE_NAME" \
        --plan "$AZ_APP_PLAN_NAME" \
        --deployment-container-image-name "$FULL_IMAGE_NAME" \
        --functions-version 4 -o table
else
    az functionapp config container set \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --image "$FULL_IMAGE_NAME" \
        --registry-server "https://${ACR_LOGIN_SERVER}" \
        --registry-username "$ACR_USER" \
        --registry-password "$ACR_PASS" -o table
fi

# Configure Settings
az functionapp config appsettings set \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --settings \
    GOOGLE_API_KEY="$GEMINI_API_KEY" \
    WEBSITES_PORT=8080 \
    WEBSITES_CONTAINER_START_TIME_LIMIT=600 \
    BYPASS_AUTH=true \
    AGENT_NAME="orchestrator" \
    AzureFunctionsJobHost__FunctionsWorkerRuntime=python -o table

echo "=== Deployment Complete ==="
echo "App URL: https://$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$AZ_RESOURCE_GROUP" --query defaultHostName -o tsv)"

