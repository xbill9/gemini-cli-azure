#!/bin/bash
# aci/deploy-aci.sh - Deploy Multi-Agent System to Azure Container Instances (ACI)

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aci"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"v$(date +%Y%m%d%H%M%S)"}
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"

echo "=== Azure ACI Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
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

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name "$AZ_ACR_NAME" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$AZ_ACR_NAME" --query "passwords[0].value" -o tsv)

# 3. Build and Push Images
build_and_push() {
    local name=$1
    local dockerfile=$2
    local tag="${ACR_LOGIN_SERVER}/${name}:${IMAGE_TAG}"
    
    echo "Building $name..."
    docker build -t "$tag" -f "$dockerfile" .
    
    echo "Pushing $name..."
    docker push "$tag"
}

build_and_push "researcher" "agents/researcher/Dockerfile"
build_and_push "judge" "agents/judge/Dockerfile"
build_and_push "content-builder" "agents/content_builder/Dockerfile"
build_and_push "orchestrator" "agents/orchestrator/Dockerfile"
build_and_push "course-creator" "app/Dockerfile"

# 4. Deploy Sub-Agents
deploy_aci() {
    local name=$1
    local image="${ACR_LOGIN_SERVER}/${name}:${IMAGE_TAG}"
    local target_port=${2:-8000}
    local dns_label="${name}-${HOSTNAME_ID}"
    shift $(( $# > 1 ? 2 : 1 ))
    
    local env_vars="$@"

    echo >&2 "Deploying $name to ACI on port $target_port..."
    az container create \
        --name "$name" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --image "$image" \
        --cpu 1 --memory 1.0 \
        --ports "$target_port" \
        --dns-name-label "$dns_label" \
        --os-type Linux \
        --registry-login-server "$ACR_LOGIN_SERVER" \
        --registry-username "$ACR_USERNAME" \
        --registry-password "$ACR_PASSWORD" \
        --environment-variables "GOOGLE_API_KEY=$GEMINI_API_KEY" "BYPASS_AUTH=true" $env_vars \
        --query "ipAddress.fqdn" -o tsv
}

RESEARCH_FQDN=$(deploy_aci "researcher" 8000)
sleep 30
JUDGE_FQDN=$(deploy_aci "judge" 8000)
sleep 30
CONTENT_FQDN=$(deploy_aci "content-builder" 8000)
sleep 30

echo "Researcher FQDN: $RESEARCH_FQDN"
echo "Judge FQDN:      $JUDGE_FQDN"
echo "Content Builder FQDN: $CONTENT_FQDN"

# 5. Deploy Orchestrator
ORCHESTRATOR_FQDN=$(deploy_aci "orchestrator" 8000 \
    "RESEARCHER_AGENT_CARD_URL=http://$RESEARCH_FQDN/a2a/researcher/.well-known/agent-card.json" \
    "JUDGE_AGENT_CARD_URL=http://$JUDGE_FQDN/a2a/judge/.well-known/agent-card.json" \
    "CONTENT_BUILDER_AGENT_CARD_URL=http://$CONTENT_FQDN/a2a/content_builder/.well-known/agent-card.json")

sleep 30
echo "Orchestrator FQDN: $ORCHESTRATOR_FQDN"

# 6. Deploy Course Creator (Main App)
APP_FQDN=$(deploy_aci "course-creator" 8080 \
    "AGENT_SERVER_URL=http://$ORCHESTRATOR_FQDN:8000" \
    "AGENT_NAME=orchestrator")

echo "=== Deployment Complete ==="
echo "Public App URL: http://$APP_FQDN:8080"
