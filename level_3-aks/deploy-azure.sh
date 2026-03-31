#!/bin/bash
# Azure Container Apps Deployment Configuration
SERVICE_NAME="biometric-scout-app"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="biometric-scout-rg"
LOCATION="canadaeast"
CONTAINERAPP_ENV="biometric-scout-env"
ACR_NAME="biometricacr$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2"

# Load Project ID and API Key
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "your-project-id") 
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "your-api-key")

# 1. Login to Azure (Assuming already logged in via az login)
# az login

# 2. Ensure Resource Group exists
echo "Ensuring Resource Group exists..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

# 3. Ensure ACR exists
echo "Ensuring ACR exists..."
az acr show --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating ACR ${ACR_NAME}..." && \
    az acr create --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --sku Basic)

# 4. Get ACR details
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

# 5. Ensure Container App Environment exists
echo "Ensuring Container App Environment exists..."
az containerapp env show --name ${CONTAINERAPP_ENV} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating Container App Environment ${CONTAINERAPP_ENV}..." && \
    az containerapp env create --name ${CONTAINERAPP_ENV} --resource-group ${RESOURCE_GROUP} --location ${LOCATION})

echo "Deploying to Azure Container App..."
az containerapp create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${SERVICE_NAME} \
    --environment ${CONTAINERAPP_ENV} \
    --image ${FULL_IMAGE_NAME} \
    --target-port 8080 \
    --ingress external \
    --registry-server ${ACR_LOGIN_SERVER} \
    --registry-username ${ACR_USERNAME} \
    --registry-password ${ACR_PASSWORD} \
    --cpu 0.5 \
    --memory 1.0Gi \
    --min-replicas 1 \
    --max-replicas 1 \
    --env-vars \
        GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
        GOOGLE_CLOUD_LOCATION="us-east1" \
        GOOGLE_GENAI_USE_VERTEXAI="False" \
        VERTEX_AI="FALSE" \
        VERTEX="no" \
        GOOGLE_API_KEY="${GEMINI_API_KEY}" \
        MODEL_ID="gemini-2.0-flash-exp" \
        PORT=8080

echo "Azure Container App Deployment complete."
echo "URL: https://$(az containerapp show --resource-group ${RESOURCE_GROUP} --name ${SERVICE_NAME} --query properties.configuration.ingress.fqdn -o tsv)"
