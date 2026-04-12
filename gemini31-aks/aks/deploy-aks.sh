#!/bin/bash
set -e

# AKS Deployment Configuration
SERVICE_NAME="biometric-scout-app"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="gemini31"
LOCATION="eastus"
AKS_CLUSTER="biometric-aks"
ACR_NAME="biometricacr$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v3"

# Load Project ID and API Key
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "your-project-id") 
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "$GOOGLE_API_KEY")

if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: GOOGLE_API_KEY is not set."
    exit 1
fi

# Ensure Resource Group exists
echo "Ensuring Resource Group exists: ${RESOURCE_GROUP}..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

# Ensure ACR exists
echo "Ensuring ACR exists: ${ACR_NAME}..."
az acr show --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating ACR ${ACR_NAME}..." && \
    az acr create --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --sku Basic)

ACR_LOGIN_SERVER=$(az acr show --name ${ACR_NAME} --query loginServer -o tsv)
az acr update --name ${ACR_NAME} --resource-group ${RESOURCE_GROUP} --admin-enabled true
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)

# Build and Push Image
echo "Building and Pushing Image: ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest..."
docker build -t ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest .
az acr login --name ${ACR_NAME}
docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest

# Ensure AKS exists
echo "Ensuring AKS exists: ${AKS_CLUSTER}..."
az aks show --name ${AKS_CLUSTER} --resource-group ${RESOURCE_GROUP} > /dev/null 2>&1 || \
    (echo "Creating AKS ${AKS_CLUSTER}..." && \
    az aks create \
        --resource-group ${RESOURCE_GROUP} \
        --name ${AKS_CLUSTER} \
        --node-count 1 \
        --generate-ssh-keys \
        --attach-acr ${ACR_NAME} \
        --location ${LOCATION})

# Get AKS Credentials
echo "Getting AKS Credentials..."
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER} --overwrite-existing

# Create Secrets in Kubernetes
echo "Creating Kubernetes Secrets..."
kubectl create secret generic adk-secrets \
    --from-literal=GOOGLE_API_KEY="${GEMINI_API_KEY}" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry acr-secret \
    --docker-server=${ACR_LOGIN_SERVER} \
    --docker-username=${ACR_USERNAME} \
    --docker-password=${ACR_PASSWORD} \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy to AKS
echo "Deploying to AKS..."

# Install NGINX Ingress Controller if not present
if ! kubectl get ingressclass nginx > /dev/null 2>&1; then
    echo "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
    echo "Waiting for Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s
fi

# Create TLS Secret if it doesn't exist
if ! kubectl get secret biometric-tls > /dev/null 2>&1; then
    echo "Generating self-signed certificate for HTTPS..."
    FQDN="biometric-scout-penguinv3.eastus.cloudapp.azure.com"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout biometric.key -out biometric.crt \
        -subj "/CN=${FQDN}"
    kubectl create secret tls biometric-tls --cert=biometric.crt --key=biometric.key
    rm biometric.key biometric.crt
fi

# Use envsubst to replace variables in manifests.yaml
export ACR_LOGIN_SERVER PROJECT_ID
envsubst < aks/manifests.yaml | kubectl apply -f -

echo "Deployment complete."
echo "Biometric Scout App is available at https://biometric-scout-penguinv3.eastus.cloudapp.azure.com"
