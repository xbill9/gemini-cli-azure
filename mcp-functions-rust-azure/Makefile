# Makefile for mcp-functions-rust-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_STORAGE_ACCOUNT ?= mcpstore$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_APP_SERVICE_PLAN ?= mcp-plan-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_FUNCTION_APP_NAME ?= mcp-func-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

# Project Variables
SERVICE_NAME := mcp-functions-rust-azure

.PHONY: all build run clean release test fmt clippy lint check docker-build deploy functionapp-deploy status git-status push-acr az-login acr-create acr-login storage-create functionapp-create functionapp-status functionapp-logs functionapp-destroy az-destroy destroy logs start stop help

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
status: local-status functionapp-status

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

# Resource Group
rg-create:
	@echo "Ensuring Resource Group $(AZ_RESOURCE_GROUP) exists..."
	@az group create --name $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION)

# ACR related targets
acr-create: rg-create
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

# Storage Account (Required for Azure Functions)
storage-create: rg-create
	@echo "Checking if Storage Account $(AZ_STORAGE_ACCOUNT) exists..."
	@az storage account show --name $(AZ_STORAGE_ACCOUNT) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Storage Account $(AZ_STORAGE_ACCOUNT)..." && \
		az storage account create --name $(AZ_STORAGE_ACCOUNT) --location $(AZ_LOCATION) --resource-group $(AZ_RESOURCE_GROUP) --sku Standard_LRS)

# --- Azure Function App Deployment ---

deploy: functionapp-deploy

functionapp-create: acr-create storage-create
	@echo "Checking if App Service Plan $(AZ_APP_SERVICE_PLAN) exists..."
	@az appservice plan show --name $(AZ_APP_SERVICE_PLAN) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating App Service Plan $(AZ_APP_SERVICE_PLAN)..." && \
		az appservice plan create --name $(AZ_APP_SERVICE_PLAN) --resource-group $(AZ_RESOURCE_GROUP) --is-linux --sku B1)
	@echo "Checking if Function App $(AZ_FUNCTION_APP_NAME) exists..."
	@az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Function App $(AZ_FUNCTION_APP_NAME)..." && \
		az functionapp create --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --storage-account $(AZ_STORAGE_ACCOUNT) --plan $(AZ_APP_SERVICE_PLAN) --image $(FULL_IMAGE_NAME) --functions-version 4 --os-type Linux)
	@echo "Configuring Function App for ACR Managed Identity..."
	@az functionapp identity assign --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP)
	@PRINCIPAL_ID=$$(az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query identity.principalId -o tsv); \
	ACR_ID=$$(az acr show --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query id -o tsv); \
	az role assignment create --assignee $$PRINCIPAL_ID --scope $$ACR_ID --role AcrPull > /dev/null 2>&1 || true
	@az functionapp config set --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_FUNCTION_APP_NAME) --generic-configurations '{"acrUseManagedIdentityCreds": true}' --always-on true
	@echo "Setting Function App environment variables..."
	@az functionapp config appsettings set --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_FUNCTION_APP_NAME) --settings ALLOWED_HOSTS=* FUNCTIONS_WORKER_RUNTIME=custom RUST_LOG=info

functionapp-deploy: push-acr functionapp-create
	@echo "Updating Function App with image $(FULL_IMAGE_NAME)..."
	@az functionapp config container set --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --image $(FULL_IMAGE_NAME)
	@echo "Function App Deployment complete."

functionapp-status:
	@echo "Checking Function App status for $(AZ_FUNCTION_APP_NAME)..."
	@az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:state, HostNames:enabledHostNames[0]}" --output table 2>/dev/null || echo "Function App $(AZ_FUNCTION_APP_NAME) not found."

endpoint:
	@az functionapp show --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "enabledHostNames[0]" --output tsv 2>/dev/null | awk '{print "https://" $$1 "/api/mcp"}' || echo "Function App $(AZ_FUNCTION_APP_NAME) not found."

functionapp-logs:
	@echo "Tailing logs for Function App $(AZ_FUNCTION_APP_NAME)..."
	@az webapp log tail --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

functionapp-destroy:
	@echo "Deleting Function App $(AZ_FUNCTION_APP_NAME) and Plan $(AZ_APP_SERVICE_PLAN)..."
	@az functionapp delete --name $(AZ_FUNCTION_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) || true
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
	@echo "Makefile for mcp-functions-rust-azure"
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
	@echo "    status           Get the status of local and Function App deployments"
	@echo "    clean            Clean the project"
	@echo "    release          Build the project for release"
	@echo "    test             Run tests"
	@echo "    fmt              Format code"
	@echo "    clippy           Lint the code"
	@echo "    docker-build     Build the Docker image"
	@echo "    deploy           Push to ACR and deploy to Function App"
	@echo "    functionapp-status Check Function App status"
	@echo "    functionapp-logs   Tail Function App logs"
	@echo "    destroy          Destroy all Azure resources in the group"
