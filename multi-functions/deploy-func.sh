#!/bin/bash
# Azure Functions Deployment Configuration for Gemini 3.1 Flash Live
# This script deploys the application as an Azure Function App using a container.

SERVICE_NAME="biometric-scout-func"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="func-rg"
LOCATION="canadaeast"
STORAGE_ACCOUNT="biometricfunc$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-6)stg"
# Unique ACR name based on hostname (reusing from deploy.sh logic)
ACR_NAME="biometricacr$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v3"

# Load Project ID and API Key from local files if they exist
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "your-project-id") 
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "$GOOGLE_API_KEY")

if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: GOOGLE_API_KEY is not set. Please set it or create ${HOME}/gemini.key"
    exit 1
fi

# Ensure Resource Group exists
echo "Ensuring Resource Group exists..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

# Ensure Storage Account exists (required for Azure Functions)
echo "Ensuring Storage Account exists..."
az storage account show --name ${STORAGE_ACCOUNT} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating Storage Account ${STORAGE_ACCOUNT}..." && \
    az storage account create --name ${STORAGE_ACCOUNT} --location ${LOCATION} --resource-group ${RESOURCE_GROUP} --sku Standard_LRS)

# Ensure ACR exists
echo "Ensuring ACR exists..."
az acr show --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating ACR ${ACR_NAME} in ${RESOURCE_GROUP}..." && \
    az acr create --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --sku Basic)

# Get ACR details
echo "Getting ACR details..."
ACR_LOGIN_SERVER=$(az acr show --name ${ACR_NAME} --query loginServer -o tsv)
az acr update --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --admin-enabled true
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)

echo "Building Docker image..."
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
docker build -t ${FULL_IMAGE_NAME} .

echo "Logging in to ACR..."
az acr login --name ${ACR_NAME}

echo "Pushing image to ACR..."
docker push ${FULL_IMAGE_NAME}

echo "Deploying to Azure Functions (Flex Consumption)..."
# We use Flex Consumption which supports containers and is optimized for events
# Note: This requires the Azure Functions extension to be installed in az cli
az functionapp create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${SERVICE_NAME} \
    --storage-account ${STORAGE_ACCOUNT} \
    --flexconsumption-location ${LOCATION} \
    --runtime python \
    --runtime-version 3.10 \
    --image ${FULL_IMAGE_NAME} \
    --registry-server ${ACR_LOGIN_SERVER} \
    --registry-username ${ACR_USERNAME} \
    --registry-password ${ACR_PASSWORD} \
    --env-vars \
        GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
        GOOGLE_CLOUD_LOCATION="us-east1" \
        GOOGLE_GENAI_USE_VERTEXAI="False" \
        GOOGLE_API_KEY="${GEMINI_API_KEY}" \
        GEMINI_API_KEY="${GEMINI_API_KEY}" \
        GEMINI_KEY="${GEMINI_API_KEY}" \
        MODEL_ID="gemini-3.1-flash-live-preview" \
        PORT=8080 \
        VIDEO_FPS="2.0" \
        HEARTBEAT_INTERVAL="10.0"

echo "Azure Functions Deployment complete."
echo "URL: https://$(az functionapp show --resource-group ${RESOURCE_GROUP} --name ${SERVICE_NAME} --query defaultHostName -o tsv)"
