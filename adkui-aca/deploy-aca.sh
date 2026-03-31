#!/bin/bash
# deploy-aca.sh - Deploy ADK UI to Azure Container Apps (ACA)

# Exit on error
set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-westus2"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}v2"}
AZ_CONTAINER_APP_NAME=${AZ_CONTAINER_APP_NAME:-"adk-app-${HOSTNAME_ID}"}
AZ_ACA_ENV_NAME=${AZ_ACA_ENV_NAME:-"adk-env-${HOSTNAME_ID}"}
IMAGE_NAME=${IMAGE_NAME:-"adk-image"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Credentials and Project Info
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION="us-central1"
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived variables
ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "=== Azure Container Apps Deployment ==="
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "Location:       $AZ_LOCATION"
echo "ACR Name:       $AZ_ACR_NAME"
echo "App Name:       $AZ_CONTAINER_APP_NAME"
echo "Env Name:       $AZ_ACA_ENV_NAME"
echo "Image:          $FULL_IMAGE_NAME"
echo "========================================"

# 1. Ensure Resource Group exists
echo "Ensuring Resource Group $AZ_RESOURCE_GROUP exists..."
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table

# 2. Ensure ACR exists
echo "Checking if ACR $AZ_ACR_NAME exists..."
if ! az acr show --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" > /dev/null 2>&1; then
    echo "Creating ACR $AZ_ACR_NAME..."
    az acr create --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" --sku Basic -o table
fi

# 3. Build and Push Docker Image
echo "Logging in to ACR..."
az acr login --name "$AZ_ACR_NAME"

echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Tagging and Pushing image..."
docker tag "$IMAGE_NAME" "$FULL_IMAGE_NAME"
docker push "$FULL_IMAGE_NAME"

# 4. Ensure ACA Environment exists
echo "Ensuring Container App Environment $AZ_ACA_ENV_NAME exists..."
if ! az containerapp env show --name "$AZ_ACA_ENV_NAME" --resource-group "$AZ_RESOURCE_GROUP" > /dev/null 2>&1; then
    echo "Creating Container App Environment $AZ_ACA_ENV_NAME..."
    az containerapp env create --name "$AZ_ACA_ENV_NAME" --resource-group "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table
fi

# 5. Enable ACR admin user (needed for easy ACA authentication)
echo "Enabling ACR admin user..."
az acr update --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" --admin-enabled true -o table

# 6. Get ACR credentials
echo "Retrieving ACR credentials..."
AZ_ACR_USERNAME=$(az acr credential show --name "$AZ_ACR_NAME" --query "username" -o tsv)
AZ_ACR_PASSWORD=$(az acr credential show --name "$AZ_ACR_NAME" --query "passwords[0].value" -o tsv)

# 7. Deploy to Azure Container App
echo "Deploying to Azure Container App..."
az containerapp create \
    --name "$AZ_CONTAINER_APP_NAME" \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --environment "$AZ_ACA_ENV_NAME" \
    --image "$FULL_IMAGE_NAME" \
    --target-port 8080 \
    --ingress external \
    --registry-server "$ACR_LOGIN_SERVER" \
    --registry-username "$AZ_ACR_USERNAME" \
    --registry-password "$AZ_ACR_PASSWORD" \
    --cpu 0.5 \
    --memory 1.0Gi \
    --min-replicas 1 \
    --max-replicas 1 \
    --env-vars \
        PORT=8080 \
        GOOGLE_CLOUD_PROJECT="$PROJECT_ID" \
        GOOGLE_CLOUD_LOCATION="$GOOGLE_CLOUD_LOCATION" \
        GOOGLE_GENAI_USE_VERTEXAI="False" \
        VERTEX_AI="FALSE" \
        VERTEX="no" \
        GOOGLE_API_KEY="$GEMINI_API_KEY" \
        GEMINI_API_KEY="$GEMINI_API_KEY" \
        MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
        ADK_DISABLE_LOCAL_STORAGE=1 \
    -o table

ENDPOINT=$(az containerapp show --name "$AZ_CONTAINER_APP_NAME" --resource-group "$AZ_RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv)

echo "Deployment complete!"
echo "Endpoint: https://$ENDPOINT"
