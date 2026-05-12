# Makefile for mcp-aca-rust-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_ACA_ENV_NAME ?= mcp-env-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACA_NAME ?= mcp-app-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

# Project Variables
SERVICE_NAME := mcp-aci-rust-azure

.PHONY: all build run clean release test fmt clippy lint check docker-build deploy status git-status local-status aca-status endpoint push-acr az-login acr-create acr-login aca-logs aca-destroy destroy logs start stop help aca-env-create aca-deploy

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
status: local-status aca-status

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

# --- Azure Container Apps (ACA) Deployment ---

deploy: aca-deploy

aca-env-create: acr-create
	@echo "Checking if ACA Environment $(AZ_ACA_ENV_NAME) exists..."
	@az containerapp env show --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating ACA Environment $(AZ_ACA_ENV_NAME)..." && \
		az containerapp env create --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION))

aca-deploy: push-acr aca-env-create
	@echo "Deploying to Azure Container App..."
	@az containerapp up \
		--name $(AZ_ACA_NAME) \
		--resource-group $(AZ_RESOURCE_GROUP) \
		--environment $(AZ_ACA_ENV_NAME) \
		--image $(FULL_IMAGE_NAME) \
		--target-port 8080 \
		--ingress external \
		--env-vars ALLOWED_HOSTS=*
	@echo "Deployment complete. Endpoint: https://$$(az containerapp show --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_ACA_NAME) --query properties.configuration.ingress.fqdn -o tsv)"

aca-status:
	@echo "Checking Azure Container App status for $(AZ_ACA_NAME)..."
	@az containerapp show --name $(AZ_ACA_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, ProvisioningState:properties.provisioningState, FQDN:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "Container App $(AZ_ACA_NAME) not found."

# Target to get the public endpoint URL
endpoint:
	@az containerapp show --name $(AZ_ACA_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "properties.configuration.ingress.fqdn" --output tsv 2>/dev/null || echo "Container App $(AZ_ACA_NAME) not found."

# Fetch ACA logs
aca-logs:
	@echo "Fetching logs for $(AZ_ACA_NAME)..."
	@az containerapp logs show --name $(AZ_ACA_NAME) --resource-group $(AZ_RESOURCE_GROUP) --follow

# Alias for aca-logs
logs: aca-logs

# Destroy ACA resources
aca-destroy:
	@echo "Deleting Azure Container App $(AZ_ACA_NAME)..."
	@az containerapp delete --name $(AZ_ACA_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "Container App $(AZ_ACA_NAME) not found."
	@echo "Deleting ACA Environment $(AZ_ACA_ENV_NAME)..."
	@az containerapp env delete --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "ACA Environment $(AZ_ACA_ENV_NAME) not found."
	@echo "Deleting ACR $(AZ_ACR_NAME)..."
	@az acr delete --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "ACR $(AZ_ACR_NAME) not found."
	@echo "Deleting Resource Group $(AZ_RESOURCE_GROUP)..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait 2>/dev/null || echo "Resource Group $(AZ_RESOURCE_GROUP) not found."

# Alias for aca-destroy
destroy: aca-destroy

git-status:
	@git status

help:
	@echo "Makefile for mcp-aca-rust-azure"
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
	@echo "    status           Get the status of local and ACA deployments"
	@echo "    clean            Clean the project"
	@echo "    release          Build the project for release"
	@echo "    test             Run tests"
	@echo "    fmt              Format code"
	@echo "    clippy           Lint the code"
	@echo "    docker-build     Build the Docker image"
	@echo "    deploy           Push to ACR and deploy to ACA"
	@echo "    aca-status       Check ACA status"
	@echo "    endpoint         Fetch the ACA FQDN"
	@echo "    logs             Tail ACA logs"
	@echo "    destroy          Destroy all Azure resources in the group"
