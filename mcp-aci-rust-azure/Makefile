# Makefile for mcp-aci-rust-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_CONTAINER_GROUP_NAME ?= mcp-container-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

# Project Variables
SERVICE_NAME := mcp-aci-rust-azure

.PHONY: all build run clean release test fmt clippy lint check docker-build deploy az-deploy status git-status local-status az-status endpoint push-acr az-login acr-create acr-login az-logs az-destroy destroy logs start stop help

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
status: local-status az-status

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

# --- Azure ACI Deployment ---

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

az-status:
	@echo "Checking Azure Container Instance status for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" --output table 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."

# Target to get the public endpoint URL
endpoint:
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."

# Fetch ACI logs
az-logs:
	@echo "Fetching logs for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container logs --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

# Alias for az-logs
logs: az-logs

# Destroy ACI resources
az-destroy:
	@echo "Deleting Azure Container Instance $(AZ_CONTAINER_GROUP_NAME)..."
	@az container delete --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."
	@echo "Deleting ACR $(AZ_ACR_NAME)..."
	@az acr delete --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "ACR $(AZ_ACR_NAME) not found."
	@echo "Deleting Resource Group $(AZ_RESOURCE_GROUP)..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait 2>/dev/null || echo "Resource Group $(AZ_RESOURCE_GROUP) not found."

# Alias for az-destroy
destroy: az-destroy

git-status:
	@git status

help:
	@echo "Makefile for mcp-aci-rust-azure"
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
	@echo "    status           Get the status of local and ACI deployments"
	@echo "    clean            Clean the project"
	@echo "    release          Build the project for release"
	@echo "    test             Run tests"
	@echo "    fmt              Format code"
	@echo "    clippy           Lint the code"
	@echo "    docker-build     Build the Docker image"
	@echo "    deploy           Push to ACR and deploy to ACI"
	@echo "    az-status        Check ACI status"
	@echo "    endpoint         Fetch the ACI FQDN"
	@echo "    logs             Tail ACI logs"
	@echo "    destroy          Destroy all Azure resources in the group"
