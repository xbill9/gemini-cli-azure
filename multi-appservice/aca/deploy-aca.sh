#!/bin/bash
# aca/deploy-aca.sh - Deploy Multi-Agent System to Azure Container Apps (ACA)

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aca"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
# Append a short random string for better uniqueness
RANDOM_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}${RANDOM_ID}"}
AZ_ACA_ENV=${AZ_ACA_ENV:-"adk-env-${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"v$(date +%Y%m%d%H%M%S)"}
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"

echo "=== Azure Container Apps Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "ACA Environment: $AZ_ACA_ENV"
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

ACR_USER=$(az acr credential show --name "$AZ_ACR_NAME" --query "username" -o tsv)
ACR_PASS=$(az acr credential show --name "$AZ_ACR_NAME" --query "passwords[0].value" -o tsv)

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

# 4. Create ACA Environment
echo "Ensuring ACA Environment exists..."
if ! az containerapp env show --name "$AZ_ACA_ENV" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az containerapp env create \
        --name "$AZ_ACA_ENV" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" -o table
fi

# 5. Deploy Container Apps
deploy_aca() {
    local service_name=$1
    local ca_name="adk-${service_name}-${HOSTNAME_ID}"
    local image="${ACR_LOGIN_SERVER}/${service_name}:${IMAGE_TAG}"
    local port=8000
    if [[ "$service_name" == "course-creator" ]]; then
        port=8080
    fi
    
    echo "Deploying $ca_name to ACA..."
    
    # Check if exists
    if ! az containerapp show --name "$ca_name" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
        az containerapp create \
            --name "$ca_name" \
            --resource-group "$AZ_RESOURCE_GROUP" \
            --environment "$AZ_ACA_ENV" \
            --image "$image" \
            --target-port $port \
            --ingress external \
            --registry-server "$ACR_LOGIN_SERVER" \
            --registry-username "$ACR_USER" \
            --registry-password "$ACR_PASS" \
            --query "properties.configuration.ingress.fqdn" -o tsv
    else
        az containerapp update \
            --name "$ca_name" \
            --resource-group "$AZ_RESOURCE_GROUP" \
            --image "$image" \
            --query "properties.configuration.ingress.fqdn" -o tsv
    fi
}

# Initial deployment to get URLs
RESEARCHER_FQDN=$(deploy_aca "researcher")
JUDGE_FQDN=$(deploy_aca "judge")
CONTENT_FQDN=$(deploy_aca "content-builder")

echo "Researcher FQDN: $RESEARCHER_FQDN"
echo "Judge FQDN:      $JUDGE_FQDN"
echo "Content Builder FQDN: $CONTENT_FQDN"

# 6. Configure Environment Variables and Re-deploy/Update
update_env() {
    local service_name=$1
    local ca_name="adk-${service_name}-${HOSTNAME_ID}"
    shift
    local env_vars="$@"
    
    echo "Updating environment variables for $ca_name..."
    az containerapp env var set \
        --name "$ca_name" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --env-vars GOOGLE_API_KEY=$GEMINI_API_KEY BYPASS_AUTH=true $env_vars -o table
}

update_env "researcher"
update_env "judge"
update_env "content-builder"

# 7. Deploy Orchestrator with references
ORCHESTRATOR_FQDN=$(deploy_aca "orchestrator")
update_env "orchestrator" \
    "RESEARCHER_AGENT_CARD_URL=https://${RESEARCHER_FQDN}/a2a/researcher/.well-known/agent-card.json" \
    "JUDGE_AGENT_CARD_URL=https://${JUDGE_FQDN}/a2a/judge/.well-known/agent-card.json" \
    "CONTENT_BUILDER_AGENT_CARD_URL=https://${CONTENT_FQDN}/a2a/content_builder/.well-known/agent-card.json"

# 8. Deploy Main App
APP_FQDN=$(deploy_aca "course-creator")
update_env "course-creator" \
    "AGENT_SERVER_URL=https://${ORCHESTRATOR_FQDN}" \
    "AGENT_NAME=orchestrator"

echo "=== Deployment Complete ==="
echo "Public App URL: https://$APP_FQDN"
