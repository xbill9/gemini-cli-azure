# Makefile for mcp-functions-python-azure

# Azure Configuration
AZ_LOCATION ?= eastus
AZ_RESOURCE_GROUP ?= mcp-rg-eastus
AZ_STORAGE_ACCOUNT_NAME ?= mcpstg$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)$(shell date +%s | tail -c 5)
AZ_FUNCTION_APP_NAME ?= mcp-func-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)

.PHONY: all install run test lint status git-status az-status endpoint pull push clean deploy az-deploy az-logs az-login az-setup

all: install run

# Install dependencies
install:
	pip install -r requirements.txt

# Run the server locally
run:
	python function_app.py

# Lint the code
lint:
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

# Test the code
test:
	pytest

# Target to show both git and Azure status
status: az-status

# Target to show git status
git-status:
	@echo "Showing git status..."
	@git status

# Target to show Azure Function status
az-status:
	@echo "Checking Azure Function status for $(AZ_FUNCTION_APP_NAME)..."
	@az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:state, DefaultHostName:defaultHostName}" --output table 2>/dev/null || echo "Function App $(AZ_FUNCTION_APP_NAME) not found."

# Target to get the public endpoint URL
endpoint:
	@az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query defaultHostName -o tsv 2>/dev/null || echo "Function App $(AZ_FUNCTION_APP_NAME) not found."

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

# Setup Azure Resources
az-setup:
	@echo "Ensuring Resource Group $(AZ_RESOURCE_GROUP) exists..."
	@az group create --name $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION)
	@echo "Ensuring Storage Account $(AZ_STORAGE_ACCOUNT_NAME) exists..."
	@az storage account show --name $(AZ_STORAGE_ACCOUNT_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Storage Account $(AZ_STORAGE_ACCOUNT_NAME)..." && \
		az storage account create --name $(AZ_STORAGE_ACCOUNT_NAME) --resource-group $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION) --sku Standard_LRS)
	@echo "Ensuring Function App $(AZ_FUNCTION_APP_NAME) exists..."
	@az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Function App $(AZ_FUNCTION_APP_NAME)..." && \
		az functionapp create \
			--name $(AZ_FUNCTION_APP_NAME) \
			--resource-group $(AZ_RESOURCE_GROUP) \
			--storage-account $(AZ_STORAGE_ACCOUNT_NAME) \
			--consumption-plan-location $(AZ_LOCATION) \
			--runtime python \
			--runtime-version 3.11 \
			--functions-version 4 \
			--os-type Linux)

# Deploy to Azure Functions
deploy: az-deploy

az-deploy: az-setup
	@echo "Creating deployment zip..."
	@zip -r deploy.zip . -x "*.git*" "*.venv*" "__pycache__*" "deploy.zip"
	@echo "Deploying to Azure Functions..."
	@az functionapp deployment source config-zip --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --src deploy.zip --build-remote true
	@rm deploy.zip
	@echo "Deployment complete. Endpoint: https://$$(az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query defaultHostName -o tsv)"

az-logs:
	@echo "Fetching logs for $(AZ_FUNCTION_APP_NAME)..."
	@az functionapp logs tail --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type d -name ".pyte*" -exec rm -rf {} +
	@find . -type d -name ".mypy*" -exec rm -rf {} +
	@rm -rf .venv deploy.zip
