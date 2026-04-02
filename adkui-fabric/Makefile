# Makefile for ADK Comic Pipeline (Azure Container Apps Deployment)

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= adk-rg-fabric
AZ_ACR_NAME ?= adkacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_ACA_ENV ?= adk-env-fabric
AZ_CONTAINER_APP_NAME ?= adk-comic-fabric
IMAGE_NAME ?= adk-image
IMAGE_TAG ?= latest

# Credentials and Project Info
PROJECT_ID := $(shell cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION := us-central1
GEMINI_API_KEY := $(shell cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all install run build test lint format type-check status git-status az-status endpoint pull push clean deploy az-login acr-create acr-build az-deploy az-logs az-destroy

all: install run

# Install dependencies
install:
	pip install -r requirements.txt

# Run the server locally
run:
	@echo "Running ADK Fabric MCP server locally..."
	python main.py

# Run the ADK Web UI locally
adk-web:
	@echo "Running ADK Web UI locally..."
	adk web . --host 0.0.0.0 --port 8080

# Target to show both git and Azure status
status: az-status

# Target to show git status
git-status:
	@echo "Showing git status..."
	@git status

# Target to show Azure Container App status
az-status:
	@echo "Checking Azure Container App status for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, ProvisioningState:provisioningState, FQDN:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "Container App $(AZ_CONTAINER_APP_NAME) not found."

# Target to get the public endpoint URL
endpoint:
	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "properties.configuration.ingress.fqdn" --output tsv 2>/dev/null || echo "Container App $(AZ_CONTAINER_APP_NAME) not found."

# Target to pull latest changes from git
pull:
	@echo "Pulling latest changes from git..."
	@git pull

# Target to push changes to git
push:
	@echo "Pushing changes to git..."
	@git push

# Azure Login
az-login:
	@echo "Logging in to Azure..."
	@az login

# ACR related targets
acr-create:
	@echo "Ensuring Resource Group $(AZ_RESOURCE_GROUP) exists..."
	@az group create --name $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION)
	@echo "Checking if ACR $(AZ_ACR_NAME) exists..."
	@az acr show --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating ACR $(AZ_ACR_NAME)..." && \
		az acr create --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --sku Basic --admin-enabled true)

# Use Azure native ACR build (no local Docker required)
acr-build: acr-create
	@echo "Building the Docker image in Azure Container Registry..."
	@az acr build --registry $(AZ_ACR_NAME) --image $(IMAGE_NAME):$(IMAGE_TAG) .

# Deploy to Azure Container Apps (Fabric Backend)
deploy: az-deploy

az-deploy: acr-build
	@echo "Deploying to Azure Container Apps..."
	@az containerapp env show --name $(AZ_ACA_ENV) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Container Apps Environment $(AZ_ACA_ENV)..." && \
		az containerapp env create --name $(AZ_ACA_ENV) --resource-group $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION))

	@$(eval ACR_USER := $(shell az acr credential show --name $(AZ_ACR_NAME) --query "username" -o tsv))
	@$(eval ACR_PASS := $(shell az acr credential show --name $(AZ_ACR_NAME) --query "passwords[0].value" -o tsv))

	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Container App $(AZ_CONTAINER_APP_NAME)..." && \
		az containerapp create --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) \
			--environment $(AZ_ACA_ENV) \
			--image $(FULL_IMAGE_NAME) \
			--target-port 8080 \
			--ingress external \
			--registry-server $(ACR_LOGIN_SERVER) \
			--registry-username $(ACR_USER) \
			--registry-password $(ACR_PASS) \
			--query "properties.configuration.ingress.fqdn")

	@echo "Updating Container App $(AZ_CONTAINER_APP_NAME) with image $(FULL_IMAGE_NAME)..."
	@az containerapp update --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) \
		--image $(FULL_IMAGE_NAME) \
		--set-env-vars \
			GOOGLE_CLOUD_PROJECT="$(PROJECT_ID)" \
			GOOGLE_CLOUD_LOCATION="$(GOOGLE_CLOUD_LOCATION)" \
			GOOGLE_GENAI_USE_VERTEXAI="False" \
			VERTEX_AI="FALSE" \
			VERTEX="no" \
			GOOGLE_API_KEY="$(GEMINI_API_KEY)" \
			GEMINI_API_KEY="$(GEMINI_API_KEY)" \
			MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
			ADK_DISABLE_LOCAL_STORAGE=1

	@echo "Deployment complete. Visit: https://$$(az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "properties.configuration.ingress.fqdn" --output tsv)"

az-logs:
	@echo "Fetching logs for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp logs show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --follow

# Target to delete the Azure Resource Group and all resources within it
az-destroy:
	@echo "WARNING: This will delete the resource group $(AZ_RESOURCE_GROUP) and all contained resources (ACR, ACA, etc.)"
	@read -p "Are you sure you want to continue? [y/N] " ans && [ $${ans:-N} = y ]
	@echo "Deleting resource group $(AZ_RESOURCE_GROUP)..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes
	@echo "Resource group $(AZ_RESOURCE_GROUP) deleted successfully."

clean:
	@echo "Cleaning up generated images and temporary files..."
	find . -name "*.log" -delete 2>/dev/null || true
	find images -name "*.png" -delete 2>/dev/null || true
	find output/images -name "*.png" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	@echo "Clean completed."
