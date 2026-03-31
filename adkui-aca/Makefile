# Makefile for ADK Comic Pipeline (Multi-Azure Deployment: ACA, ACI, App Service)

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= adk-rg-westus2
HOSTNAME_ID := $(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME ?= adkacr$(HOSTNAME_ID)v2
AZ_APP_SERVICE_NAME ?= adk-app-$(HOSTNAME_ID)
AZ_CONTAINER_GROUP_NAME ?= adk-container-$(HOSTNAME_ID)
AZ_CONTAINER_APP_NAME ?= adk-app-$(HOSTNAME_ID)
AZ_ACA_ENV_NAME ?= adk-env-$(HOSTNAME_ID)
AZ_PLAN_NAME ?= adk-asp
IMAGE_NAME ?= adk-image
IMAGE_TAG ?= latest

# Credentials and Project Info
PROJECT_ID := $(shell cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION := us-central1
GEMINI_API_KEY := $(shell cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all clean test deploy run endpoint status az-status az-logs docker-build az-login acr-create acr-login push-acr az-deploy deploy-azure az-destroy az-deploy-aci deploy-aci az-status-aci az-logs-aci az-destroy-aci deploy-aca az-deploy-aca az-status-aca az-logs-aca az-destroy-aca az-aca-env

all: run

# Run the app locally (assuming adk is installed)
run:
	@echo "Running ADK Web UI locally..."
	adk web . --host 0.0.0.0 --port 8080

clean:
	@echo "Cleaning up generated images and temporary files..."
	find . -name "*.log" -delete 2>/dev/null || true
	find images -name "*.png" -delete 2>/dev/null || true
	find output/images -name "*.png" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	@echo "Clean completed."

# Build the Docker image
docker-build:
	@echo "Building the Docker image..."
	docker build -t $(IMAGE_NAME) .

# Azure Login
az-login:
	@echo "Logging in to Azure..."
	az login

# ACR related targets
acr-create:
	@echo "Ensuring Resource Group $(AZ_RESOURCE_GROUP) exists..."
	az group create --name $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION)
	@echo "Checking if ACR $(AZ_ACR_NAME) exists..."
	az acr show --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating ACR $(AZ_ACR_NAME)..." && \
		az acr create --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --sku Basic)

acr-login:
	@echo "Logging in to Azure Container Registry..."
	az acr login --name $(AZ_ACR_NAME)

push-acr: docker-build acr-create acr-login
	@echo "Pushing the Docker image to ACR..."
	docker tag $(IMAGE_NAME) $(FULL_IMAGE_NAME)
	docker push $(FULL_IMAGE_NAME)

# Deploy to Azure Container Apps (Preferred)
deploy: deploy-aca

deploy-aca: ./deploy-aca.sh
	./deploy-aca.sh

# Alternative ACA deployment via Makefile logic
az-aca-env:
	@echo "Checking if Container App Environment $(AZ_ACA_ENV_NAME) exists..."
	@az containerapp env show --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Container App Environment $(AZ_ACA_ENV_NAME)..." && \
		az containerapp env create --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION))

az-deploy-aca: push-acr az-aca-env
	@echo "Enabling ACR admin user..."
	@az acr update --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --admin-enabled true
	@echo "Deploying to Azure Container App..."
	@AZ_ACR_USERNAME=$$(az acr credential show --name $(AZ_ACR_NAME) --query "username" -o tsv) && \
	AZ_ACR_PASSWORD=$$(az acr credential show --name $(AZ_ACR_NAME) --query "passwords[0].value" -o tsv) && \
	az containerapp create \
		--name $(AZ_CONTAINER_APP_NAME) \
		--resource-group $(AZ_RESOURCE_GROUP) \
		--environment $(AZ_ACA_ENV_NAME) \
		--image $(FULL_IMAGE_NAME) \
		--target-port 8080 \
		--ingress external \
		--registry-server $(ACR_LOGIN_SERVER) \
		--registry-username $$AZ_ACR_USERNAME \
		--registry-password $$AZ_ACR_PASSWORD \
		--cpu 0.5 \
		--memory 1.0Gi \
		--min-replicas 1 \
		--max-replicas 1 \
		--env-vars \
			PORT=8080 \
			GOOGLE_CLOUD_PROJECT="$(PROJECT_ID)" \
			GOOGLE_CLOUD_LOCATION="$(GOOGLE_CLOUD_LOCATION)" \
			GOOGLE_GENAI_USE_VERTEXAI="False" \
			VERTEX_AI="FALSE" \
			VERTEX="no" \
			GOOGLE_API_KEY="$(GEMINI_API_KEY)" \
			GEMINI_API_KEY="$(GEMINI_API_KEY)" \
			MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
			ADK_DISABLE_LOCAL_STORAGE=1
	@echo "Deployment complete. Endpoint: https://$$(az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query properties.configuration.ingress.fqdn -o tsv)"

# Deploy to Azure App Service
deploy-appservice: deploy-azure

deploy-azure: push-acr
	@echo "Deploying to Azure App Service..."
	@az appservice plan show --name $(AZ_PLAN_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating App Service Plan $(AZ_PLAN_NAME)..." && \
		az appservice plan create --name $(AZ_PLAN_NAME) --resource-group $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION) --is-linux --sku B1)
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Web App $(AZ_APP_SERVICE_NAME)..." && \
		az webapp create --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --plan $(AZ_PLAN_NAME) --container-image-name $(FULL_IMAGE_NAME))
	@echo "Updating Web App $(AZ_APP_SERVICE_NAME) with image $(FULL_IMAGE_NAME)..."
	@az webapp config container set --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --container-image-name $(FULL_IMAGE_NAME)
	@echo "Setting environment variables..."
	@az webapp config appsettings set --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --settings \
		PORT=8080 \
		WEBSITES_PORT=8080 \
		GOOGLE_CLOUD_PROJECT="$(PROJECT_ID)" \
		GOOGLE_CLOUD_LOCATION="$(GOOGLE_CLOUD_LOCATION)" \
		GOOGLE_GENAI_USE_VERTEXAI="False" \
		VERTEX_AI="FALSE" \
		VERTEX="no" \
		GOOGLE_API_KEY="$(GEMINI_API_KEY)" \
		GEMINI_API_KEY="$(GEMINI_API_KEY)" \
		MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
		ADK_DISABLE_LOCAL_STORAGE=1
	@echo "Deployment complete. Visit: http://$$(az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "defaultHostName" --output tsv)"

# Deploy to Azure Container Instance
deploy-aci: az-deploy-aci

az-deploy-aci: push-acr
	@echo "Enabling ACR admin user..."
	@az acr update --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --admin-enabled true
	@echo "Waiting 30 seconds for ACR credentials to propagate..."
	@sleep 30
	@echo "Deploying to Azure Container Instance..."
	@AZ_ACR_USERNAME=$$(az acr credential show --name $(AZ_ACR_NAME) --query "username" -o tsv) && \
	AZ_ACR_PASSWORD=$$(az acr credential show --name $(AZ_ACR_NAME) --query "passwords[0].value" -o tsv) && \
	az container create \
		--resource-group $(AZ_RESOURCE_GROUP) \
		--name $(AZ_CONTAINER_GROUP_NAME) \
		--image $(FULL_IMAGE_NAME) \
		--dns-name-label $(AZ_CONTAINER_GROUP_NAME) \
		--ports 8080 \
		--registry-login-server $(ACR_LOGIN_SERVER) \
		--registry-username $$AZ_ACR_USERNAME \
		--registry-password $$AZ_ACR_PASSWORD \
		--cpu 1 \
		--memory 1.5 \
		--location $(AZ_LOCATION) \
		--os-type Linux \
		--environment-variables \
			PORT=8080 \
			GOOGLE_CLOUD_PROJECT="$(PROJECT_ID)" \
			GOOGLE_CLOUD_LOCATION="$(GOOGLE_CLOUD_LOCATION)" \
			GOOGLE_GENAI_USE_VERTEXAI="False" \
			VERTEX_AI="FALSE" \
			VERTEX="no" \
			GOOGLE_API_KEY="$(GEMINI_API_KEY)" \
			GEMINI_API_KEY="$(GEMINI_API_KEY)" \
			MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
			ADK_DISABLE_LOCAL_STORAGE=1
	@echo "Deployment complete. Endpoint: http://$$(az container show --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_CONTAINER_GROUP_NAME) --query ipAddress.fqdn -o tsv):8080"

status: az-status-aca

az-status-aca:
	@echo "Checking Azure Container App status for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "Container App $(AZ_CONTAINER_APP_NAME) not found."

az-status: az-status-appservice

az-status-appservice:
	@echo "Checking Azure App Service status for $(AZ_APP_SERVICE_NAME)..."
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:state, Host:defaultHostName}" --output table 2>/dev/null || echo "App Service $(AZ_APP_SERVICE_NAME) not found."

az-status-aci:
	@echo "Checking Azure Container Instance status for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" --output table 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."

logs: az-logs-aca

az-logs-aca:
	@echo "Fetching logs for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp logs show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

az-logs-appservice:
	@echo "Fetching logs for $(AZ_APP_SERVICE_NAME)..."
	@az webapp log tail --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP)

az-logs-aci:
	@echo "Fetching logs for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container logs --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

endpoint:
	@echo "--- Azure Container App Endpoint ---"
	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "properties.configuration.ingress.fqdn" --output tsv 2>/dev/null || echo "N/A"
	@echo "--- Azure App Service Endpoint ---"
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "defaultHostName" --output tsv 2>/dev/null || echo "N/A"
	@echo "--- Azure Container Instance Endpoint ---"
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "N/A"

az-destroy:
	@echo "Destroying Azure Resource Group $(AZ_RESOURCE_GROUP)..."
	az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Resource Group deletion initiated. This may take a few minutes."

az-destroy-aca:
	@echo "Deleting Azure Container App $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp delete --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "Container App $(AZ_CONTAINER_APP_NAME) not found."

az-destroy-aci:
	@echo "Deleting Azure Container Instance $(AZ_CONTAINER_GROUP_NAME)..."
	@az container delete --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."
