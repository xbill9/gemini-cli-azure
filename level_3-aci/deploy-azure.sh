#!/bin/bash
# Azure ACI Deployment Configuration
SERVICE_NAME="biometric-scout-service"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="level_3-aci"
LOCATION="canadaeast"
CONTAINER_GROUP_NAME="biometric-scout-aci"
ACR_NAME="biometricacrpenguinv2"

# Load Project ID and API Key
PROJECT_ID=$(cat ~/project_id.txt) # For Vertex AI
GEMINI_API_KEY=$(cat ${HOME}/gemini.key)

# 1. Login to Azure (Assuming already logged in via az login)
# az login

# 2. Ensure Resource Group exists
echo "Ensuring Resource Group exists..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

# 3. Ensure ACR exists
echo "Ensuring ACR exists..."
az acr create --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --sku Basic 2>/dev/null || echo "ACR already exists or error creating it."

# 4. Get ACR details
echo "Getting ACR details..."
ACR_LOGIN_SERVER=$(az acr show --name ${ACR_NAME} --query loginServer -o tsv)
az acr update --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --admin-enabled true
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)

echo "Building Docker image..."
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
# Navigate to the correct directory before building
cd $HOME/gemini-cli-azure/level_3-aci
docker build -t ${FULL_IMAGE_NAME} .

echo "Logging in to ACR..."
az acr login --name ${ACR_NAME}

echo "Pushing image to ACR..."
docker push ${FULL_IMAGE_NAME}

echo "Deploying to Azure Container Instance..."
az container create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${CONTAINER_GROUP_NAME} \
    --image ${FULL_IMAGE_NAME} \
    --dns-name-label ${CONTAINER_GROUP_NAME} \
    --ports 8080 \
    --registry-login-server ${ACR_LOGIN_SERVER} \
    --registry-username ${ACR_USERNAME} \
    --registry-password ${ACR_PASSWORD} \
    --cpu 1 \
    --memory 1.5 \
    --location ${LOCATION} \
    --os-type Linux \
    --environment-variables \
        GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
        GOOGLE_CLOUD_LOCATION="us-east1" \
        GOOGLE_GENAI_USE_VERTEXAI="False" \
        VERTEX_AI="FALSE" \
        VERTEX="no" \
        GOOGLE_API_KEY="${GEMINI_API_KEY}" \
        MODEL_ID="gemini-2.5-flash-native-audio-latest" \
        PORT=8080

echo "Azure ACI Deployment complete."
echo "URL: http://$(az container show --resource-group ${RESOURCE_GROUP} --name ${CONTAINER_GROUP_NAME} --query ipAddress.fqdn -o tsv):8080"
