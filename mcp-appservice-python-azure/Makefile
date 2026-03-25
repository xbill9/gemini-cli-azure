# Makefile for mcp-appservice-python-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_APP_SERVICE_NAME ?= mcp-app-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_PLAN_NAME ?= mcp-asp
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= latest

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all install run build test lint format type-check status git-status az-status endpoint pull push clean deploy docker-build az-login acr-create acr-login push-acr az-deploy az-logs az-destroy

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

# Target to show Azure App Service status
az-status:
	@echo "Checking Azure App Service status for $(AZ_APP_SERVICE_NAME)..."
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:state, Host:defaultHostName}" --output table 2>/dev/null || echo "App Service $(AZ_APP_SERVICE_NAME) not found."

# Target to get the public endpoint URL
endpoint:
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "defaultHostName" --output tsv 2>/dev/null || echo "App Service $(AZ_APP_SERVICE_NAME) not found."

# Target to pull latest changes from git
pull:
	@echo "Pulling latest changes from git..."
	@git pull

# Target to push changes to git
push:
	@echo "Pushing changes to git..."
	@git push

# Build the Docker image
docker-build:
	@echo "Building the Docker image..."
	@docker build -t $(IMAGE_NAME) .

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
		az acr create --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --sku Basic)

acr-login:
	@echo "Logging in to Azure Container Registry..."
	@az acr login --name $(AZ_ACR_NAME)

push-acr: docker-build acr-create acr-login
	@echo "Pushing the Docker image to ACR..."
	@docker tag $(IMAGE_NAME) $(FULL_IMAGE_NAME)
	@docker push $(FULL_IMAGE_NAME)

# Deploy to Azure App Service
deploy: az-deploy

az-deploy: push-acr
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
	@az webapp config appsettings set --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --settings PORT=8080 WEBSITES_PORT=8080
	@echo "Deployment complete. Visit: http://$$(az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "defaultHostName" --output tsv)"

az-logs:
	@echo "Fetching logs for $(AZ_APP_SERVICE_NAME)..."
	@az webapp log tail --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP)

az-destroy:
	@echo "Destroying Azure resources in $(AZ_RESOURCE_GROUP)..."
	@echo "This will delete all resources within this resource group."
	az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Resource group deletion started (non-blocking). It may take several minutes to complete."

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type d -name ".pyte*" -exec rm -rf {} +
	@find . -type d -name ".mypy*" -exec rm -rf {} +
	@rm -rf .venv
