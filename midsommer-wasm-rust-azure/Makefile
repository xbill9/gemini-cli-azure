# Midsommer Madness - Flutter Build and Development Automation Makefile
# Swedish-themed retro arcade game refactored to Flutter.

JAVA_HOME ?= /usr/lib/jvm/java-25-openjdk-amd64
export JAVA_HOME
export PATH := $(JAVA_HOME)/bin:$(PATH)
export ANDROID_HOME := /home/xbill/android-sdk

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= midsommer-rg
AZ_ACR_NAME ?= midsommeracr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_ACA_ENV_NAME ?= midsommer-env-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACA_NAME ?= midsommer-app-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= midsommer-game-image
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || date +%s)

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: help dev run build-apk build-ios install-apk clean logcat deploy aca-status endpoint docker-build test build-wasm check-requirements az-login acr-create acr-login push-acr aca-env-create aca-deploy aca-logs destroy aca-destroy logs

# Default target: show help
help:
	@echo "========================================================================"
	@echo "🇸🇪  Midsommer Madness Azure ACA & Development Controls  🇸🇪"
	@echo "========================================================================"
	@echo "Available commands:"
	@echo "  make dev          - Start the local web server for browser play (from assets/)"
	@echo "  make build-wasm   - Compile the Rust WebAssembly physics and particle engine"
	@echo "  make test         - Run the Flutter unit/widget test suite"
	@echo "  make build-apk    - Compile the Flutter App and build Debug APK"
	@echo "  make build-ios    - Compile the Flutter App and build iOS app (no codesign)"
	@echo "  make install-apk  - Install the compiled debug APK on a connected device/emulator"
	@echo "  make clean        - Clean Flutter build outputs and temporary caches"
	@echo "  make logcat       - Monitor application logs using Flutter logger"
	@echo "  make check-requirements - Check if Azure CLI (az) and Docker are installed"
	@echo "  make az-login     - Log in to Azure CLI"
	@echo "  make deploy       - Package WASM, build Docker, push to ACR and deploy to ACA"
	@echo "  make aca-status   - Check status of Azure Container App"
	@echo "  make endpoint     - Get the public endpoint FQDN of the deployed container app"
	@echo "  make aca-logs     - Follow/stream logs from Azure Container App"
	@echo "  make destroy      - Delete all created Azure resources (ACA, ACR, Resource Group)"
	@echo "  Note: Pushing/merging to 'master' on GitHub automatically triggers deployment."
	@echo "========================================================================"

# WebAssembly compilation
build-wasm:
	@echo "Compiling Rust WebAssembly module..."
	cd game-wasm && cargo build --target wasm32-unknown-unknown --release
	@mkdir -p assets
	@cp game-wasm/target/wasm32-unknown-unknown/release/midsommer_wasm.wasm assets/game_physics.wasm
	@echo -n "const WASM_BASE64 = '" > assets/wasm_binary.js
	@base64 -w 0 assets/game_physics.wasm >> assets/wasm_binary.js
	@echo "';" >> assets/wasm_binary.js
	@echo "WebAssembly compiled and base64 helper assets/wasm_binary.js generated successfully!"

# Development server
dev: run

run: build-wasm
	npm run dev

# Build debug APK
build-apk: build-wasm
	@echo "Building Flutter Debug APK..."
	flutter build apk --debug

# Build iOS App (without code signing)
build-ios: build-wasm
	@echo "Building Flutter iOS App (without code signing)..."
	flutter build ios --no-codesign

# Install debug APK to device
install-apk:
	@echo "Installing Debug APK to connected device/emulator..."
	flutter install

# Clean the workspace
clean:
	@echo "Cleaning Flutter project build directories..."
	flutter clean
	@rm -rf build target server.pid server.log
	@echo "Cleaning Rust build target..."
	cargo clean

# Logs monitoring for debugging
logcat:
	flutter logs

# Build the Docker image
docker-build: build-wasm
	@echo "Building the Docker image..."
	@docker build -t $(IMAGE_NAME) .

# --- Azure CLI Targets ---

# Check for required tools
check-requirements:
	@command -v az >/dev/null 2>&1 || { echo >&2 "Azure CLI (az) is required but not installed. Aborting."; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is required but not installed. Aborting."; exit 1; }
	@echo "All requirements met."

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

acr-login:
	@echo "Logging in to Azure Container Registry..."
	@az acr login --name $(AZ_ACR_NAME)

push-acr: docker-build acr-create acr-login
	@echo "Tagging and pushing the Docker image to ACR..."
	@docker tag $(IMAGE_NAME) $(FULL_IMAGE_NAME)
	@docker push $(FULL_IMAGE_NAME)

# --- Azure Container Apps (ACA) Deployment ---

deploy: check-requirements aca-deploy

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

# Run Flutter tests
test:
	@echo "Running Flutter widget and unit tests..."
	flutter test
