# Makefile for mcp-appservice-rust-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_APP_SERVICE_PLAN ?= mcp-plan-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_APP_SERVICE_NAME ?= mcp-app-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

# Project Variables
SERVICE_NAME := mcp-appservice-rust-azure

.PHONY: all build run clean release test fmt clippy lint check docker-build deploy appservice-deploy status git-status push-acr az-login acr-create acr-login appservice-create appservice-status appservice-logs appservice-destroy az-destroy destroy logs start stop help

# The default target
all: build

# Build the project for development
build:
	@echo "Building the Rust project..."
	@cargo build

# Run the project locally
run:
	@echo "Running the Rust project..."
	@cargo run --release

# Start the server in the background
start: release
	@echo "Starting the MCP server..."
	@nohup ./target/release/$(SERVICE_NAME) > server.log 2>&1 & echo $$! > server.pid
	@echo "Server started with PID $$(cat server.pid)"

# Stop the background server
stop:
	@if [ -f server.pid ]; then \
		PID=$$(cat server.pid); \
		echo "Stopping $(SERVICE_NAME) (PID $$PID)..."; \
		kill $$PID || true; \
		rm server.pid; \
	else \
		echo "$(SERVICE_NAME) is not running."; \
	fi

# Get the status
status: local-status appservice-status

local-status:
	@if [ -f server.pid ]; then \
		PID=$$(cat server.pid); \
		if ps -p $$PID > /dev/null; then \
			echo "$(SERVICE_NAME) is running locally (PID $$PID)."; \
		else \
			echo "$(SERVICE_NAME) PID file exists but process is not running."; \
			rm server.pid; \
		fi \
	else \
		echo "$(SERVICE_NAME) is not running locally."; \
	fi

# Clean the project
clean:
	@echo "Cleaning the project..."
	@cargo clean
	@rm -f server.pid server.log

# Build the project for release
release:
	@echo "Building Release..."
	@cargo build --release

# Run tests
test:
	@echo "Running tests..."
	@cargo test

# Format the code
fmt:
	@echo "Formatting code..."
	@cargo fmt --all

# Lint the code
clippy:
	@echo "Linting code..."
	@cargo clippy -- -D warnings

# Alias for clippy
lint: clippy

# Check the code
check:
	@echo "Checking the code..."
	@cargo check

# Build the Docker image
docker-build:
	@echo "Building the Docker image..."
	@docker build -t $(IMAGE_NAME) .

# --- Azure CLI Targets ---

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
	@echo "Tagging and pushing the Docker image to ACR..."
	@docker tag $(IMAGE_NAME) $(FULL_IMAGE_NAME)
	@docker push $(FULL_IMAGE_NAME)

# --- Azure App Service Deployment ---

deploy: appservice-deploy

appservice-create: acr-create
	@echo "Checking if App Service Plan $(AZ_APP_SERVICE_PLAN) exists..."
	@az appservice plan show --name $(AZ_APP_SERVICE_PLAN) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating App Service Plan $(AZ_APP_SERVICE_PLAN)..." && \
		az appservice plan create --name $(AZ_APP_SERVICE_PLAN) --resource-group $(AZ_RESOURCE_GROUP) --is-linux --sku B1)
	@echo "Checking if App Service $(AZ_APP_SERVICE_NAME) exists..."
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating App Service $(AZ_APP_SERVICE_NAME)..." && \
		az webapp create --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --plan $(AZ_APP_SERVICE_PLAN) --deployment-container-image-name $(FULL_IMAGE_NAME))
	@echo "Configuring App Service for ACR Managed Identity..."
	@az webapp identity assign --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP)
	@PRINCIPAL_ID=$$(az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query identity.principalId -o tsv); \
	ACR_ID=$$(az acr show --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query id -o tsv); \
	az role assignment create --assignee $$PRINCIPAL_ID --scope $$ACR_ID --role AcrPull > /dev/null 2>&1 || true
	@az webapp config set --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_APP_SERVICE_NAME) --generic-configurations '{"acrUseManagedIdentityCreds": true}' --always-on true
	@echo "Enabling HTTP logging..."
	@az webapp log config --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --web-server-logging filesystem
	@echo "Setting App Service environment variables..."
	@az webapp config appsettings set --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_APP_SERVICE_NAME) --settings PORT=8080 ALLOWED_HOSTS=* WEBSITES_PORT=8080 WEBSITE_HTTPLOGGING_RETENTION_DAYS=7

appservice-deploy: push-acr appservice-create
	@echo "Updating App Service with image $(FULL_IMAGE_NAME)..."
	@az webapp config container set --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --container-image-name $(FULL_IMAGE_NAME)
	@echo "App Service Deployment complete."

appservice-status:
	@echo "Checking App Service status for $(AZ_APP_SERVICE_NAME)..."
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:state, HostNames:enabledHostNames[0]}" --output table 2>/dev/null || echo "App Service $(AZ_APP_SERVICE_NAME) not found."

endpoint:
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "enabledHostNames[0]" --output tsv 2>/dev/null | awk '{print "https://" $$1}' || echo "App Service $(AZ_APP_SERVICE_NAME) not found."

appservice-logs:
	@echo "Tailing logs for App Service $(AZ_APP_SERVICE_NAME)..."
	@az webapp log tail --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP)

appservice-destroy:
	@echo "Deleting App Service $(AZ_APP_SERVICE_NAME) and Plan $(AZ_APP_SERVICE_PLAN)..."
	@az webapp delete --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes || true
	@az appservice plan delete --name $(AZ_APP_SERVICE_PLAN) --resource-group $(AZ_RESOURCE_GROUP) --yes || true

# Target to delete all Azure resources by deleting the resource group
az-destroy:
	@echo "Deleting Resource Group $(AZ_RESOURCE_GROUP) and all associated resources..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Deletion of $(AZ_RESOURCE_GROUP) initiated in the background."

# Alias for az-destroy to clean all resources
destroy: az-destroy

git-status:
	@git status

help:
	@echo "Makefile for mcp-appservice-rust-azure"
	@echo ""
	@echo "Usage:"
	@echo "    make <target>"
	@echo ""
	@echo "Targets:"
	@echo "    all              (default) same as 'build'"
	@echo "    build            Build the project for development"
	@echo "    run              Run the project locally"
	@echo "    start            Start the server in the background"
	@echo "    stop             Stop the background server"
	@echo "    status           Get the status of local and App Service deployments"
	@echo "    clean            Clean the project"
	@echo "    release          Build the project for release"
	@echo "    test             Run tests"
	@echo "    fmt              Format code"
	@echo "    clippy           Lint the code"
	@echo "    docker-build     Build the Docker image"
	@echo "    deploy           Push to ACR and deploy to App Service"
	@echo "    appservice-status Check App Service status"
	@echo "    appservice-logs   Tail App Service logs"
	@echo "    destroy          Destroy all Azure resources in the group"
