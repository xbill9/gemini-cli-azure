# Makefile for mcp-fabric-python-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-fabric
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_ACA_ENV ?= mcp-env-fabric
AZ_CONTAINER_APP_NAME ?= mcp-fabric-server
IMAGE_NAME ?= mcp-fabric-image
IMAGE_TAG ?= latest

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all install run build test lint format type-check status git-status az-status endpoint pull push clean deploy az-login acr-create acr-build az-deploy az-logs

all: install run

# Install dependencies
install:
	pip install -r requirements.txt

# Run the server locally
run:
	python main.py

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
		--image $(FULL_IMAGE_NAME)
	
	@echo "Deployment complete. Visit: https://$$(az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "properties.configuration.ingress.fqdn" --output tsv)"

az-logs:
	@echo "Fetching logs for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp logs show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --follow

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type d -name ".pyte*" -exec rm -rf {} +
	@find . -type d -name ".mypy*" -exec rm -rf {} +
	@rm -rf .venv
