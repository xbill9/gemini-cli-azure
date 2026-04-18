#!/bin/bash
# Azure Container Instances Deployment with SSL (Caddy Sidecar)
SERVICE_NAME="biometric-scout-aci-ssl"
IMAGE_NAME="biometric-scout-image"
RESOURCE_GROUP="aci-east"
LOCATION="eastus"

# Storage for Caddy SSL persistence
STORAGE_ACCOUNT="biometricstorage$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)v1"
ACR_NAME="biometricacreastus$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)v1"

# Load API Key
GEMINI_API_KEY=$(cat ${HOME}/gemini.key 2>/dev/null || echo "$GOOGLE_API_KEY")
PROJECT_ID=$(cat ~/project_id.txt 2>/dev/null || echo "your-project-id")

if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: GOOGLE_API_KEY is not set."
    exit 1
fi

# Get ACR and Storage details
ACR_LOGIN_SERVER=$(az acr show --name ${ACR_NAME} --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)
STORAGE_KEY=$(az storage account keys list --resource-group ${RESOURCE_GROUP} --account-name ${STORAGE_ACCOUNT} --query "[0].value" -o tsv)

DNS_NAME_LABEL="biometric-scout-ssl-$(hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)"
FQDN="${DNS_NAME_LABEL}.${LOCATION}.azurecontainer.io"

echo "Deploying with SSL to FQDN: $FQDN"

# Base64 encode the Caddyfile for secret volume
# Use clear newlines for the Caddyfile
CADDYFILE_CONTENT=$(cat <<EOF
{
    email xbill9@gmail.com
}
$FQDN {
    reverse_proxy localhost:8080
}
EOF
)
CADDYFILE_B64=$(echo "$CADDYFILE_CONTENT" | base64 -w 0)

# Create ACI YAML definition
cat <<EOF > aci-deployment-ssl.yaml
apiVersion: '2021-10-01'
location: $LOCATION
name: $SERVICE_NAME
properties:
  containers:
  - name: biometric-app
    properties:
      image: $ACR_LOGIN_SERVER/$IMAGE_NAME:latest
      resources:
        requests:
          cpu: 1
          memoryInGb: 1.5
      ports:
      - port: 8080
      environmentVariables:
      - name: GOOGLE_API_KEY
        value: $GEMINI_API_KEY
      - name: MODEL_ID
        value: gemini-3.1-flash-live-preview
      - name: PORT
        value: '8080'
      - name: VIDEO_FPS
        value: '2.0'
      - name: HEARTBEAT_INTERVAL
        value: '10.0'
      - name: GOOGLE_CLOUD_PROJECT
        value: $PROJECT_ID
      - name: GOOGLE_CLOUD_LOCATION
        value: us-east1
      - name: GOOGLE_GENAI_USE_VERTEXAI
        value: 'False'
  - name: caddy-ssl
    properties:
      image: $ACR_LOGIN_SERVER/caddy:latest
      command: ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
      resources:
        requests:
          cpu: 0.5
          memoryInGb: 0.5
      ports:
      - port: 80
      - port: 443
      volumeMounts:
      - name: caddy-config
        mountPath: /etc/caddy
      - name: caddy-data
        mountPath: /data
  osType: Linux
  ipAddress:
    type: Public
    ports:
    - protocol: tcp
      port: 80
    - protocol: tcp
      port: 443
    dnsNameLabel: $DNS_NAME_LABEL
  imageRegistryCredentials:
  - server: $ACR_LOGIN_SERVER
    username: $ACR_USERNAME
    password: $ACR_PASSWORD
  volumes:
  - name: caddy-config
    secret:
      Caddyfile: $CADDYFILE_B64
  - name: caddy-data
    azureFile:
      shareName: caddy-data
      storageAccountName: $STORAGE_ACCOUNT
      storageAccountKey: $STORAGE_KEY
EOF

echo "Updating ACI deployment via YAML..."
az container create --resource-group $RESOURCE_GROUP --file aci-deployment-ssl.yaml

echo "SSL Deployment complete."
echo "URL: https://$FQDN"
