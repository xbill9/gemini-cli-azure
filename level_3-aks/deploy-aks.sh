#!/bin/bash
# AKS Deployment Configuration
SERVICE_NAME="biometric-scout-app"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="biometric-scout-rg"
LOCATION="canadaeast"
ACR_NAME="biometricacr$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2"
AKS_CLUSTER_NAME="biometric-scout-aks"

# Load Project ID and API Key
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "your-project-id") 
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "your-api-key")

# 1. Ensure Resource Group exists
echo "Ensuring Resource Group exists..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

# 2. Ensure ACR exists
echo "Ensuring ACR exists..."
az acr show --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating ACR ${ACR_NAME}..." && \
    az acr create --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --sku Basic)

# 3. Get ACR details and Build/Push Image
ACR_LOGIN_SERVER=$(az acr show --name ${ACR_NAME} --query loginServer -o tsv)
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"

echo "Building Docker image..."
docker build -t ${FULL_IMAGE_NAME} .

echo "Logging in to ACR..."
az acr login --name ${ACR_NAME}

echo "Pushing image to ACR..."
docker push ${FULL_IMAGE_NAME}

# 4. Ensure AKS cluster exists
echo "Ensuring AKS cluster exists..."
az aks show --name ${AKS_CLUSTER_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating AKS cluster ${AKS_CLUSTER_NAME}..." && \
    az aks create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${AKS_CLUSTER_NAME} \
        --node-count 1 \
        --generate-ssh-keys \
        --attach-acr ${ACR_NAME})

# 5. Get AKS credentials
echo "Getting credentials for AKS cluster ${AKS_CLUSTER_NAME}..."
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --overwrite-existing

# 6. Deploy to AKS
echo "Deploying to AKS..."
sed -e "s|IMAGE_PLACEHOLDER|${FULL_IMAGE_NAME}|g" \
    -e "s|PROJECT_ID_PLACEHOLDER|${PROJECT_ID}|g" \
    -e "s|GEMINI_API_KEY_PLACEHOLDER|${GEMINI_API_KEY}|g" \
    k8s.yaml | kubectl apply -f -

echo "AKS Deployment complete."
echo "Waiting for LoadBalancer IP..."
kubectl get svc biometric-scout-service -w | head -n 2
