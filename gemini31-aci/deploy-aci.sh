#!/bin/bash
# Azure Container Instances Deployment Configuration for Gemini 3.1 Flash Live
SERVICE_NAME="biometric-scout-aci"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="aci"
LOCATION="canadaeast"
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

echo "Deploying to Azure Container Instance (ACI)..."
# gemini-3.1-flash-live-preview requires Multimodal Live API
# We set up the environment variables for the container
DNS_NAME_LABEL="biometric-scout-$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)"

az container create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${SERVICE_NAME} \
    --image ${FULL_IMAGE_NAME} \
    --cpu 1 \
    --memory 1.5 \
    --registry-login-server ${ACR_LOGIN_SERVER} \
    --registry-username ${ACR_USERNAME} \
    --registry-password ${ACR_PASSWORD} \
    --ip-address public \
    --ports 8080 \
    --dns-name-label ${DNS_NAME_LABEL} \
    --restart-policy Always \
    --environment-variables \
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

echo "Azure Container Instance Deployment complete."
echo "URL: http://$(az container show --resource-group ${RESOURCE_GROUP} --name ${SERVICE_NAME} --query ipAddress.fqdn -o tsv):8080"
echo "IP: $(az container show --resource-group ${RESOURCE_GROUP} --name ${SERVICE_NAME} --query ipAddress.ip -o tsv)"
