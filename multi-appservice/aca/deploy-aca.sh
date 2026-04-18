#!/bin/bash
# aca/deploy-aca.sh - Deploy Multi-Agent System to Azure Container Apps (ACA)

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
# Append a short random string for better uniqueness in global ACR namespace
RANDOM_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}${RANDOM_ID}"}
AZ_ACA_ENV_NAME=${AZ_ACA_ENV_NAME:-"adk-env-${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"v$(date +%Y%m%d%H%M%S)"}
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"

echo "=== Azure ACA Deployment ==="
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

# 4. Create Container Apps Environment
echo "Ensuring ACA Environment exists..."
if ! az containerapp env show --name "$AZ_ACA_ENV_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az containerapp env create \
        --name "$AZ_ACA_ENV_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" -o table
fi

# 5. Deploy Sub-Agents
deploy_aca() {
    local name=$1
    local image="${ACR_LOGIN_SERVER}/${name}:${IMAGE_TAG}"
    local target_port=${2:-8000}
    shift $(( $# > 1 ? 2 : 1 ))
    
    local env_vars="$@"

    echo >&2 "Deploying $name to ACA on port $target_port..."
    az containerapp create \
        --name "$name" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --environment "$AZ_ACA_ENV_NAME" \
        --image "$image" \
        --target-port "$target_port" \
        --ingress external \
        --registry-server "$ACR_LOGIN_SERVER" \
        --secrets "gemini-key=$GEMINI_API_KEY" \
        --env-vars "GOOGLE_API_KEY=secretref:gemini-key" "BYPASS_AUTH=true" $env_vars \
        --query "properties.configuration.ingress.fqdn" -o tsv
}

RESEARCH_FQDN=$(deploy_aca "researcher" 8000)
JUDGE_FQDN=$(deploy_aca "judge" 8000)
CONTENT_FQDN=$(deploy_aca "content-builder" 8000)

echo "Researcher FQDN: $RESEARCH_FQDN"
echo "Judge FQDN:      $JUDGE_FQDN"
echo "Content Builder FQDN: $CONTENT_FQDN"

# 6. Deploy Orchestrator
ORCHESTRATOR_FQDN=$(deploy_aca "orchestrator" 8000 \
    "RESEARCHER_AGENT_CARD_URL=https://$RESEARCH_FQDN/a2a/researcher/.well-known/agent-card.json" \
    "JUDGE_AGENT_CARD_URL=https://$JUDGE_FQDN/a2a/judge/.well-known/agent-card.json" \
    "CONTENT_BUILDER_AGENT_CARD_URL=https://$CONTENT_FQDN/a2a/content_builder/.well-known/agent-card.json")

echo "Orchestrator FQDN: $ORCHESTRATOR_FQDN"

# 7. Deploy Course Creator (Main App)
APP_FQDN=$(deploy_aca "course-creator" 8080 \
    "AGENT_SERVER_URL=https://$ORCHESTRATOR_FQDN" \
    "AGENT_NAME=orchestrator")

echo "=== Deployment Complete ==="
echo "Public App URL: https://$APP_FQDN"
