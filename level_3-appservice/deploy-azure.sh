#!/bin/bash
# Azure Deployment Configuration
SERVICE_NAME="biometric-scout-service"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="biometric-scout-rg"
LOCATION="westus2"
PLAN_NAME="biometric-scout-plan"
APP_NAME="biometric-scout-app"
ACR_NAME="biometricacrcomglitn"

# Load Project ID and API Key
PROJECT_ID=$(cat ~/project_id.txt) # For Vertex AI
GEMINI_API_KEY=$(cat ${HOME}/gemini.key)

# 1. Login to Azure (Assuming already logged in via az login)
# az login

# 2. Get ACR details
echo "Getting ACR details..."
ACR_LOGIN_SERVER=$(az acr show --name ${ACR_NAME} --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)

echo "Building Docker image..."
# Use the ACR login server in the tag
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
docker build -t ${FULL_IMAGE_NAME} .

echo "Logging in to ACR..."
# Use az acr login which is more reliable than docker login with credentials in some envs
az acr login --name ${ACR_NAME}

echo "Pushing image to ACR..."
docker push ${FULL_IMAGE_NAME}

echo "Ensuring Resource Group exists..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

echo "Ensuring App Service Plan exists..."
if ! az appservice plan show --name ${PLAN_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1; then
    az appservice plan create \
        --name ${PLAN_NAME} \
        --resource-group ${RESOURCE_GROUP} \
        --location ${LOCATION} \
        --sku B1 \
        --is-linux
fi

echo "Ensuring Web App exists..."
if ! az webapp show --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1; then
    az webapp create \
        --name ${APP_NAME} \
        --resource-group ${RESOURCE_GROUP} \
        --plan ${PLAN_NAME} \
        --deployment-container-image-name ${FULL_IMAGE_NAME}
fi

echo "Configuring container settings..."
# Using non-deprecated flags if possible, or just staying consistent
az webapp config container set \
    --name ${APP_NAME} \
    --resource-group ${RESOURCE_GROUP} \
    --docker-custom-image-name ${FULL_IMAGE_NAME} \
    --docker-registry-server-url https://${ACR_LOGIN_SERVER} \
    --docker-registry-server-user ${ACR_USERNAME} \
    --docker-registry-server-password ${ACR_PASSWORD}

echo "Configuring environment variables for Azure App Service..."
az webapp config appsettings set \
    --name ${APP_NAME} \
    --resource-group ${RESOURCE_GROUP} \
    --settings \
        GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
        GOOGLE_CLOUD_LOCATION="us-central1" \
        GOOGLE_GENAI_USE_VERTEXAI="False" \
        VERTEX_AI="FALSE" \
        VERTEX="no" \
        GOOGLE_API_KEY="${GEMINI_API_KEY}" \
        MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
        PORT=8080 \
        WEBSITES_PORT=8080

echo "Azure App Service Deployment complete."
echo "URL: https://$(az webapp show --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --query defaultHostName -o tsv)"
