#!/bin/bash
# Azure App Service Deployment Configuration for Gemini 3.1 Flash Live
SERVICE_NAME="biometric-scout-app"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="aca" # Keeping the same RG name or we could change to 'appservice-rg'
LOCATION="canadaeast"
APPSERVICE_PLAN="biometric-scout-plan"

# Unique ACR name based on hostname
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

# Ensure ACR exists
echo "Ensuring ACR exists..."
az acr show --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating ACR ${ACR_NAME}..." && \
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

# Ensure App Service Plan exists
echo "Ensuring App Service Plan exists..."
az appservice plan show --name ${APPSERVICE_PLAN} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating App Service Plan ${APPSERVICE_PLAN}..." && \
    az appservice plan create --name ${APPSERVICE_PLAN} --resource-group ${RESOURCE_GROUP} --location ${LOCATION} --is-linux --sku B1)

# Ensure Web App exists and is configured for containers
echo "Ensuring Web App exists..."
az webapp show --name ${SERVICE_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating Web App ${SERVICE_NAME}..." && \
    az webapp create --name ${SERVICE_NAME} --resource-group ${RESOURCE_GROUP} --plan ${APPSERVICE_PLAN} --deployment-container-image-name ${FULL_IMAGE_NAME})

echo "Configuring Web App container settings..."
az webapp config container set --name ${SERVICE_NAME} --resource-group ${RESOURCE_GROUP} \
    --docker-custom-image-name ${FULL_IMAGE_NAME} \
    --docker-registry-server-url https://${ACR_LOGIN_SERVER} \
    --docker-registry-server-user ${ACR_USERNAME} \
    --docker-registry-server-password ${ACR_PASSWORD}

echo "Configuring environment variables..."
az webapp config appsettings set --resource-group ${RESOURCE_GROUP} --name ${SERVICE_NAME} --settings \
    GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
    GOOGLE_CLOUD_LOCATION="us-east1" \
    GOOGLE_GENAI_USE_VERTEXAI="False" \
    GOOGLE_API_KEY="${GEMINI_API_KEY}" \
    GEMINI_API_KEY="${GEMINI_API_KEY}" \
    GEMINI_KEY="${GEMINI_API_KEY}" \
    MODEL_ID="gemini-3.1-flash-live-preview" \
    PORT=8080 \
    VIDEO_FPS="2.0" \
    HEARTBEAT_INTERVAL="10.0" \
    WEBSITES_PORT=8080

echo "Azure App Service Deployment complete."
echo "URL: https://$(az webapp show --resource-group ${RESOURCE_GROUP} --name ${SERVICE_NAME} --query defaultHostName -o tsv)"
