# Makefile for mcp-aks-rust-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_AKS_CLUSTER_NAME ?= mcp-aks-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

# Project Variables
SERVICE_NAME := mcp-aks-rust-azure

.PHONY: all build run clean release test fmt clippy lint check docker-build deploy aks-deploy status git-status endpoint push-acr az-login acr-create acr-login aks-create aks-get-credentials aks-status aks-destroy az-destroy destroy logs start stop help

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
status: local-status aks-status

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

# --- Azure AKS Deployment ---

deploy: aks-deploy

# AKS related targets
aks-create: acr-create
	@echo "Checking if AKS cluster $(AZ_AKS_CLUSTER_NAME) exists..."
	@az aks show --name $(AZ_AKS_CLUSTER_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating AKS cluster $(AZ_AKS_CLUSTER_NAME)..." && \
		az aks create \
			--resource-group $(AZ_RESOURCE_GROUP) \
			--name $(AZ_AKS_CLUSTER_NAME) \
			--node-count 1 \
			--generate-ssh-keys \
			--attach-acr $(AZ_ACR_NAME))

aks-get-credentials:
	@echo "Getting credentials for AKS cluster $(AZ_AKS_CLUSTER_NAME)..."
	@az aks get-credentials --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_AKS_CLUSTER_NAME) --overwrite-existing

aks-deploy: push-acr aks-get-credentials
	@echo "Deploying to AKS..."
	@sed "s|IMAGE_PLACEHOLDER|$(FULL_IMAGE_NAME)|g" k8s.yaml | kubectl apply -f -
	@echo "AKS Deployment complete."

aks-status:
	@echo "Checking AKS status for $(AZ_AKS_CLUSTER_NAME)..."
	@az aks show --name $(AZ_AKS_CLUSTER_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:provisioningState, K8sVersion:kubernetesVersion}" --output table 2>/dev/null || echo "AKS Cluster $(AZ_AKS_CLUSTER_NAME) not found."
	@if kubectl get nodes >/dev/null 2>&1; then \
		echo "Kubernetes Services:"; \
		kubectl get svc mcp-server-service; \
		echo "Kubernetes Pods:"; \
		kubectl get pods -l app=mcp-server; \
	fi

# Target to get the public endpoint URL
endpoint:
	@echo "AKS Endpoint:"
	@kubectl get svc mcp-server-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "AKS service not found or IP not yet assigned."

# Monitor AKS logs
logs:
	@echo "Tailing logs for AKS pods with label app=mcp-server..."
	@kubectl logs -l app=mcp-server --follow

aks-destroy:
	@echo "Deleting AKS cluster $(AZ_AKS_CLUSTER_NAME)..."
	@az aks delete --name $(AZ_AKS_CLUSTER_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes --no-wait

# Target to delete all Azure resources by deleting the resource group
az-destroy:
	@echo "Deleting Resource Group $(AZ_RESOURCE_GROUP) and all associated resources..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Deletion of $(AZ_RESOURCE_GROUP) initiated in the background."

# Alias for az-destroy to clean all AKS resources
destroy: az-destroy

git-status:
	@git status

help:
	@echo "Makefile for mcp-aks-rust-azure"
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
	@echo "    status           Get the status of local and AKS deployments"
	@echo "    clean            Clean the project"
	@echo "    release          Build the project for release"
	@echo "    test             Run tests"
	@echo "    fmt              Format code"
	@echo "    clippy           Lint the code"
	@echo "    docker-build     Build the Docker image"
	@echo "    deploy           Push to ACR and deploy to AKS"
	@echo "    aks-create       Create AKS cluster"
	@echo "    aks-status       Check AKS status"
	@echo "    endpoint         Fetch the LoadBalancer IP"
	@echo "    logs             Tail AKS logs"
	@echo "    destroy          Destroy all Azure resources in the group"
