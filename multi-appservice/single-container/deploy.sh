#!/bin/bash
# single-container/deploy.sh - Deploy the all-in-one container to Azure App Service

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-as"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
RANDOM_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}${RANDOM_ID}"}
AZ_APP_PLAN_NAME=${AZ_APP_PLAN_NAME:-"adk-plan-${HOSTNAME_ID}"}
WEBAPP_NAME="adk-${HOSTNAME_ID}-full"
IMAGE_TAG="v$(date +%Y%m%d%H%M%S)"
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/all-in-one:${IMAGE_TAG}"

echo "=== Azure All-in-One Deployment ==="
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "Web App Name:   $WEBAPP_NAME"
echo "============================="

# 1. Create Resource Group
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table

# 2. Create/Get ACR
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

# 4. Create App Service Plan
if ! az appservice plan show --name "$AZ_APP_PLAN_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az appservice plan create \
        --name "$AZ_APP_PLAN_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" \
        --is-linux \
        --sku B1 -o table
fi

# 5. Create Web App
if ! az webapp show --name "$WEBAPP_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az webapp create \
        --name "$WEBAPP_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --plan "$AZ_APP_PLAN_NAME" \
        --container-image-name "$FULL_IMAGE_NAME" -o table
else
    az webapp config container set \
        --name "$WEBAPP_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --container-image-name "$FULL_IMAGE_NAME" \
        --docker-registry-server-url "https://${ACR_LOGIN_SERVER}" \
        --docker-registry-server-user "$ACR_USER" \
        --docker-registry-server-password "$ACR_PASS" -o table
fi

# Configure Settings
az webapp config appsettings set \
    --name "$WEBAPP_NAME" \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --settings \
    GOOGLE_API_KEY="$GEMINI_API_KEY" \
    WEBSITES_PORT=8080 \
    WEBSITES_CONTAINER_START_TIME_LIMIT=600 \
    BYPASS_AUTH=true -o table

echo "=== Deployment Complete ==="
echo "App URL: https://$(az webapp show --name "$WEBAPP_NAME" --resource-group "$AZ_RESOURCE_GROUP" --query defaultHostName -o tsv)"
