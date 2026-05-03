#!/bin/bash
# fabric/deploy.sh - Deploy Multi-Agent System to Azure Container Apps and Fabric

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-fabric"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}"}
AZ_ACA_ENV_NAME=${AZ_ACA_ENV_NAME:-"adk-env-${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"v$(date +%Y%m%d%H%M%S)"}
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"

echo "=== Azure Fabric Stacked Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "ACA Environment: $AZ_ACA_ENV_NAME"
echo "============================="

# 1. Create Resource Group
echo "Ensuring Resource Group exists..."
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table

# 2. Create ACR
echo "Ensuring ACR exists..."
if ! az acr show --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az acr create --resource-group "$AZ_RESOURCE_GROUP" --name "$AZ_ACR_NAME" --sku Basic --admin-enabled true -o table
fi
az acr login --name "$AZ_ACR_NAME"

# 3. Build and Push Unified Image
build_and_push() {
    local name=$1
    local dockerfile=$2
    local tag="${ACR_LOGIN_SERVER}/${name}:${IMAGE_TAG}"
    
    echo "Building $name..."
    docker build -t "$tag" -f "$dockerfile" .
    
    echo "Pushing $name..."
    docker push "$tag"
}

build_and_push "course-creator-unified" "Dockerfile"

# 4. Create Container Apps Environment
echo "Ensuring ACA Environment exists..."
if ! az containerapp env show --name "$AZ_ACA_ENV_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az containerapp env create \
        --name "$AZ_ACA_ENV_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" -o table
fi

# 5. Deploy Unified App
echo >&2 "Deploying unified app to ACA on port 8080..."
APP_FQDN=$(az containerapp create \
    --name "course-creator" \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --environment "$AZ_ACA_ENV_NAME" \
    --image "${ACR_LOGIN_SERVER}/course-creator-unified:${IMAGE_TAG}" \
    --target-port 8080 \
    --ingress external \
    --registry-server "$ACR_LOGIN_SERVER" \
    --secrets "gemini-key=$GEMINI_API_KEY" \
    --env-vars "GOOGLE_API_KEY=secretref:gemini-key" "BYPASS_AUTH=true" "PORT=8080" \
    --query "properties.configuration.ingress.fqdn" -o tsv)

echo "=== Deployment Complete ==="
echo "Public App URL: https://$APP_FQDN"

# 8. Microsoft Fabric Integration
echo "--- Microsoft Fabric Integration ---"
AZ_CLIENT_ID=${AZ_CLIENT_ID:-"YOUR_ENTRA_APP_ID"}
MANIFEST_FILE="fabric/WorkloadManifest.xml"
cp fabric/WorkloadManifest.xml.template "$MANIFEST_FILE"
sed -i "s/{{APP_FQDN}}/$APP_FQDN/g" "$MANIFEST_FILE"
sed -i "s/{{AZ_CLIENT_ID}}/$AZ_CLIENT_ID/g" "$MANIFEST_FILE"

echo "Microsoft Fabric Workload Manifest generated: $MANIFEST_FILE"
echo "================================================================="
echo "NEXT STEPS FOR MICROSOFT FABRIC:"
echo "1. Register your backend App in Microsoft Entra ID (if not done)."
echo "2. Add the 'Fabric.Extend' scope to your App registration."
echo "3. Upload the generated '$MANIFEST_FILE' to the Fabric Admin Portal."
echo "4. For local testing, use the Fabric DevGateway pointing to:"
echo "   https://$APP_FQDN"
echo "================================================================="
