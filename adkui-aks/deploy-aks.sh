#!/bin/bash
# deploy-aks.sh - Deploy ADK UI to Azure Kubernetes Service (AKS)

# Exit on error
set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-westus2"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}v2"}
AZ_AKS_CLUSTER_NAME=${AZ_AKS_CLUSTER_NAME:-"adk-aks-${HOSTNAME_ID}"}
IMAGE_NAME=${IMAGE_NAME:-"adk-image"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Credentials and Project Info
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION="us-central1"
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived Azure variables
ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"
ACR_IMAGE="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "=== Azure AKS Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "AKS Cluster:    $AZ_AKS_CLUSTER_NAME"
echo "Image:          $ACR_IMAGE"
echo "============================="

# 1. Create Resource Group
echo "Ensuring Resource Group $AZ_RESOURCE_GROUP exists..."
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION"

# 2. Create ACR
echo "Checking if ACR $AZ_ACR_NAME exists..."
if ! az acr show --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" > /dev/null 2>&1; then
    echo "Creating ACR $AZ_ACR_NAME..."
    az acr create --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" --sku Basic
fi

# 3. Authenticate with ACR
echo "Logging in to Azure Container Registry..."
az acr login --name "$AZ_ACR_NAME"

# 4. Build and Push Docker Image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Tagging and Pushing image..."
docker tag "$IMAGE_NAME" "$ACR_IMAGE"
docker push "$ACR_IMAGE"

# 5. Create AKS Cluster (if it doesn't exist)
echo "Checking if AKS Cluster $AZ_AKS_CLUSTER_NAME exists..."
if ! az aks show --name "$AZ_AKS_CLUSTER_NAME" --resource-group "$AZ_RESOURCE_GROUP" > /dev/null 2>&1; then
    echo "Creating AKS Cluster $AZ_AKS_CLUSTER_NAME (this may take several minutes)..."
    az aks create \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --name "$AZ_AKS_CLUSTER_NAME" \
        --node-count 1 \
        --generate-ssh-keys \
        --attach-acr "$AZ_ACR_NAME" \
        --location "$AZ_LOCATION"
fi

# 6. Get AKS Credentials
echo "Updating kubeconfig for AKS Cluster $AZ_AKS_CLUSTER_NAME..."
az aks get-credentials --resource-group "$AZ_RESOURCE_GROUP" --name "$AZ_AKS_CLUSTER_NAME" --overwrite-existing

# 7. Create Secrets in Kubernetes
echo "Creating/Updating adk-secrets in Kubernetes..."
kubectl create secret generic adk-secrets \
    --from-literal=GOOGLE_API_KEY="$GEMINI_API_KEY" \
    --from-literal=GEMINI_API_KEY="$GEMINI_API_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

# 8. Deploy to AKS
echo "Deploying to Azure AKS..."
# Use sed to replace variables in k8s-aks.yaml
sed -e "s|\${ACR_IMAGE}|$ACR_IMAGE|g" \
    -e "s|\${PROJECT_ID}|$PROJECT_ID|g" \
    -e "s|\${GOOGLE_CLOUD_LOCATION}|$GOOGLE_CLOUD_LOCATION|g" \
    k8s-aks.yaml | kubectl apply -f -

echo "Waiting for deployment to complete..."
kubectl rollout status deployment/adk-app

echo "Deployment complete!"
echo "Service External IP (may take a moment to appear):"
kubectl get svc adk-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo ""
