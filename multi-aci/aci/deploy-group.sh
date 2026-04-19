#!/bin/bash
# aci/deploy-group.sh - Deploy Multi-Agent System as a single Azure Container Group

set -e

# Default configurations
AZ_LOCATION=${AZ_LOCATION:-"westus2"}
AZ_RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-"adk-rg-aci"}
HOSTNAME_ID=$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME=${AZ_ACR_NAME:-"adkacr${HOSTNAME_ID}"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
GOOGLE_API_KEY=${GOOGLE_API_KEY:-$(cat ${HOME}/gemini.key 2>/dev/null || echo "")}
GENAI_MODEL=${GENAI_MODEL:-"gemini-2.5-flash"}
LOG_LEVEL=${LOG_LEVEL:-"DEBUG"}
GROUP_NAME="course-creator-group"

ACR_LOGIN_SERVER="${AZ_ACR_NAME}.azurecr.io"

echo "=== Azure ACI Container Group Deployment ==="
echo "Azure Location: $AZ_LOCATION"
echo "Resource Group: $AZ_RESOURCE_GROUP"
echo "ACR Name:       $AZ_ACR_NAME"
echo "Group Name:     $GROUP_NAME"
echo "============================================"

# 1. Create Resource Group
az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o table

# 2. Ensure ACR exists and get credentials
if ! az acr show --name "$AZ_ACR_NAME" --resource-group "$AZ_RESOURCE_GROUP" &>/dev/null; then
    az acr create --resource-group "$AZ_RESOURCE_GROUP" --name "$AZ_ACR_NAME" --sku Basic --admin-enabled true -o table
fi
ACR_USERNAME=$(az acr credential show --name "$AZ_ACR_NAME" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$AZ_ACR_NAME" --query "passwords[0].value" -o tsv)

# 3. Generate ACI YAML
YAML_FILE="aci-container-group.yaml"
echo "Generating $YAML_FILE..."

LOG_ANALYTICS_CONFIG=""
if [ -n "$AZ_WORKSPACE_ID" ] && [ -n "$AZ_WORKSPACE_KEY" ]; then
    LOG_ANALYTICS_CONFIG="logAnalytics:
  workspaceId: $AZ_WORKSPACE_ID
  workspaceKey: $AZ_WORKSPACE_KEY"
fi

cat <<EOF > $YAML_FILE
apiVersion: '2023-05-01'
location: $AZ_LOCATION
name: $GROUP_NAME
$LOG_ANALYTICS_CONFIG
properties:
  containers:
  - name: researcher
    properties:
      image: ${ACR_LOGIN_SERVER}/researcher:${IMAGE_TAG}
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 1.0
      ports:
      - port: 8001
      environmentVariables:
      - name: GOOGLE_API_KEY
        value: $GOOGLE_API_KEY
      - name: GENAI_MODEL
        value: $GENAI_MODEL
      - name: LOG_LEVEL
        value: $LOG_LEVEL
      - name: PORT
        value: '8001'
      - name: BYPASS_AUTH
        value: 'true'
  - name: judge
    properties:
      image: ${ACR_LOGIN_SERVER}/judge:${IMAGE_TAG}
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 1.0
      ports:
      - port: 8002
      environmentVariables:
      - name: GOOGLE_API_KEY
        value: $GOOGLE_API_KEY
      - name: GENAI_MODEL
        value: $GENAI_MODEL
      - name: LOG_LEVEL
        value: $LOG_LEVEL
      - name: PORT
        value: '8002'
      - name: BYPASS_AUTH
        value: 'true'
  - name: content-builder
    properties:
      image: ${ACR_LOGIN_SERVER}/content-builder:${IMAGE_TAG}
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 1.0
      ports:
      - port: 8003
      environmentVariables:
      - name: GOOGLE_API_KEY
        value: $GOOGLE_API_KEY
      - name: GENAI_MODEL
        value: $GENAI_MODEL
      - name: LOG_LEVEL
        value: $LOG_LEVEL
      - name: PORT
        value: '8003'
      - name: BYPASS_AUTH
        value: 'true'
  - name: orchestrator
    properties:
      image: ${ACR_LOGIN_SERVER}/orchestrator:${IMAGE_TAG}
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 1.0
      ports:
      - port: 8004
      environmentVariables:
      - name: GOOGLE_API_KEY
        value: $GOOGLE_API_KEY
      - name: GENAI_MODEL
        value: $GENAI_MODEL
      - name: LOG_LEVEL
        value: $LOG_LEVEL
      - name: PORT
        value: '8004'
      - name: BYPASS_AUTH
        value: 'true'
      - name: RESEARCHER_AGENT_CARD_URL
        value: http://localhost:8001/a2a/researcher/.well-known/agent-card.json
      - name: JUDGE_AGENT_CARD_URL
        value: http://localhost:8002/a2a/judge/.well-known/agent-card.json
      - name: CONTENT_BUILDER_AGENT_CARD_URL
        value: http://localhost:8003/a2a/content_builder/.well-known/agent-card.json
  - name: course-creator
    properties:
      image: ${ACR_LOGIN_SERVER}/course-creator:${IMAGE_TAG}
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 1.0
      ports:
      - port: 8080
      environmentVariables:
      - name: GOOGLE_API_KEY
        value: $GOOGLE_API_KEY
      - name: GENAI_MODEL
        value: $GENAI_MODEL
      - name: LOG_LEVEL
        value: $LOG_LEVEL
      - name: PORT
        value: '8080'
      - name: AGENT_SERVER_URL
        value: http://localhost:8004
      - name: AGENT_NAME
        value: orchestrator
  osType: Linux
  restartPolicy: Always
  ipAddress:
    type: Public
    ports:
    - protocol: Tcp
      port: 8080
    dnsNameLabel: course-creator-group-${HOSTNAME_ID}
  imageRegistryCredentials:
  - server: $ACR_LOGIN_SERVER
    username: $ACR_USERNAME
    password: $ACR_PASSWORD
EOF

# 5. Deploy Container Group
echo "Deploying Container Group from $YAML_FILE..."
az container create --resource-group "$AZ_RESOURCE_GROUP" --file $YAML_FILE

echo "=== Deployment Complete ==="
FQDN=$(az container show --name $GROUP_NAME --resource-group "$AZ_RESOURCE_GROUP" --query "ipAddress.fqdn" -o tsv)
echo "Public App URL: http://$FQDN:8080"
