#!/bin/bash
# Azure Functions Deployment Script for Gemini 3.1 Flash Live
SERVICE_NAME="biometric-scout-func"
RESOURCE_GROUP="func-rg"
LOCATION="canadaeast"
# Shorten STORAGE_ACCOUNT name to stay under 24 chars
STORAGE_ACCOUNT="biofunc$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v3"

# Load Project ID and API Key from local files if they exist
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "your-project-id") 
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "$GOOGLE_API_KEY")

if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: GOOGLE_API_KEY is not set. Please set it or create ${HOME}/gemini.key"
    exit 1
fi

# Ensure Resource Group exists
echo "Ensuring Resource Group exists: ${RESOURCE_GROUP}..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

# Ensure Storage Account exists
echo "Ensuring Storage Account exists: ${STORAGE_ACCOUNT}..."
az storage account show --name ${STORAGE_ACCOUNT} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating Storage Account ${STORAGE_ACCOUNT}..." && \
    az storage account create --name ${STORAGE_ACCOUNT} --resource-group ${RESOURCE_GROUP} --location ${LOCATION} --sku Standard_LRS)

# Create Function App (Consumption Plan)
echo "Creating Function App: ${SERVICE_NAME}..."
az functionapp show --name ${SERVICE_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating Function App ${SERVICE_NAME} on Consumption Plan..." && \
    az functionapp create \
        --name ${SERVICE_NAME} \
        --storage-account ${STORAGE_ACCOUNT} \
        --consumption-plan-location ${LOCATION} \
        --resource-group ${RESOURCE_GROUP} \
        --functions-version 4 \
        --os-type Linux \
        --runtime python \
        --runtime-version 3.11)

# Set App Settings (Environment Variables)
echo "Configuring App Settings for ${SERVICE_NAME}..."
az functionapp config appsettings set \
    --name ${SERVICE_NAME} \
    --resource-group ${RESOURCE_GROUP} \
    --settings \
        GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
        GOOGLE_API_KEY="${GEMINI_API_KEY}" \
        GEMINI_API_KEY="${GEMINI_API_KEY}" \
        GEMINI_KEY="${GEMINI_API_KEY}" \
        MODEL_ID="gemini-3.1-flash-live-preview" \
        VIDEO_FPS="2.0" \
        HEARTBEAT_INTERVAL="10.0"

echo "Azure Functions Deployment Infrastructure is ready."
echo "Note: To publish the code, use 'func azure functionapp publish ${SERVICE_NAME}'"
echo "Or use 'az functionapp deployment source config-zip -g ${RESOURCE_GROUP} -n ${SERVICE_NAME} --src <zip-file>'"
