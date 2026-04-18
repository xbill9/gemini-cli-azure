#!/bin/bash
# appservice/deploy-appservice.sh - Deploy Multi-Agent System to Azure App Service (for Containers)

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-as"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
# Append a short random string for better uniqueness in global ACR namespace
RANDOM_ID=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6 ; echo '')
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}${RANDOM_ID}"}
AZ_APP_PLAN_NAME=${AZ_APP_PLAN_NAME:-"adk-plan-${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"v$(date +%Y%m%d%H%M%S)"}
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "")

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"

echo "=== Azure App Service Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "App Service Plan: $AZ_APP_PLAN_NAME"
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

# 4. Create App Service Plan
echo "Ensuring App Service Plan exists..."
if ! az appservice plan show --name "$AZ_APP_PLAN_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az appservice plan create \
        --name "$AZ_APP_PLAN_NAME" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --location "$AZ_LOCATION" \
        --is-linux \
        --sku B1 -o table
fi

# 5. Deploy Web Apps
deploy_webapp() {
    local service_name=$1
    local webapp_name="adk-${HOSTNAME_ID}-${service_name}"
    local image="${ACR_LOGIN_SERVER}/${service_name}:${IMAGE_TAG}"
    
    echo >&2 "Deploying $webapp_name to App Service..."
    
    # Check if webapp exists
    if ! az webapp show --name "$webapp_name" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
        az webapp create \
            --name "$webapp_name" \
            --resource-group "$AZ_RESOURCE_GROUP" \
            --plan "$AZ_APP_PLAN_NAME" \
            --deployment-container-image-name "$image" -o table
    else
        az webapp config container set \
            --name "$webapp_name" \
            --resource-group "$AZ_RESOURCE_GROUP" \
            --deployment-container-image-name "$image" \
            --docker-registry-server-url "https://${ACR_LOGIN_SERVER}" \
            --docker-registry-server-user "$ACR_USER" \
            --docker-registry-server-password "$ACR_PASS" -o table
    fi

    # Configure ACR access
    az webapp config container set \
        --name "$webapp_name" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --docker-registry-server-url "https://${ACR_LOGIN_SERVER}" \
        --docker-registry-server-user "$ACR_USER" \
        --docker-registry-server-password "$ACR_PASS" -o table

    # Add environment variables
    shift 1
    local env_vars="$@"

    local settings="GOOGLE_API_KEY=$GEMINI_API_KEY BYPASS_AUTH=true"
    if [[ "$service_name" == "course-creator" ]]; then
        settings="$settings WEBSITES_PORT=8080 $env_vars"
    else
        settings="$settings WEBSITES_PORT=8000 $env_vars"
    fi

    az webapp config appsettings set \
        --name "$webapp_name" \
        --resource-group "$AZ_RESOURCE_GROUP" \
        --settings $settings -o table

    echo "$webapp_name.azurewebsites.net"
}

RESEARCHER_URL=$(deploy_webapp "researcher")
JUDGE_URL=$(deploy_webapp "judge")
CONTENT_URL=$(deploy_webapp "content-builder")

echo "Researcher URL: $RESEARCHER_URL"
echo "Judge URL:      $JUDGE_URL"
echo "Content Builder URL: $CONTENT_URL"

# 6. Deploy Orchestrator
ORCHESTRATOR_URL=$(deploy_webapp "orchestrator" \
    "RESEARCHER_AGENT_CARD_URL=https://$RESEARCHER_URL/a2a/researcher/.well-known/agent-card.json" \
    "JUDGE_AGENT_CARD_URL=https://$JUDGE_URL/a2a/judge/.well-known/agent-card.json" \
    "CONTENT_BUILDER_AGENT_CARD_URL=https://$CONTENT_URL/a2a/content_builder/.well-known/agent-card.json")

echo "Orchestrator URL: $ORCHESTRATOR_URL"

# 7. Deploy Course Creator (Main App)
APP_URL=$(deploy_webapp "course-creator" \
    "AGENT_SERVER_URL=https://$ORCHESTRATOR_URL" \
    "AGENT_NAME=orchestrator")

echo "=== Deployment Complete ==="
echo "Public App URL: https://$APP_URL"
