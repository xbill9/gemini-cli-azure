# Makefile for mcp-aci-python-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_CONTAINER_GROUP_NAME ?= mcp-container-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
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

# Target to show Azure Container Instance status
az-status:
	@echo "Checking Azure Container Instance status for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" --output table 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."

# Target to get the public endpoint URL
endpoint:
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."

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

# Deploy to Azure Container Instance
deploy: az-deploy

az-deploy: push-acr
	@echo "Enabling ACR admin user..."
	@az acr update --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --admin-enabled true
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
		--environment-variables PORT=8080
	@echo "Deployment complete. Endpoint: http://$$(az container show --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_CONTAINER_GROUP_NAME) --query ipAddress.fqdn -o tsv):8080"

az-logs:
	@echo "Fetching logs for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container logs --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

# Destroy Azure resources
az-destroy:
	@echo "Deleting Azure Container Instance $(AZ_CONTAINER_GROUP_NAME)..."
	@az container delete --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."
	@echo "Deleting ACR $(AZ_ACR_NAME)..."
	@az acr delete --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "ACR $(AZ_ACR_NAME) not found."
	@echo "Deleting Resource Group $(AZ_RESOURCE_GROUP)..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait 2>/dev/null || echo "Resource Group $(AZ_RESOURCE_GROUP) not found."

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type d -name ".pyte*" -exec rm -rf {} +
	@find . -type d -name ".mypy*" -exec rm -rf {} +
	@rm -rf .venv
