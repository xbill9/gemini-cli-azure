# Makefile for ADK Comic Pipeline (App Service Deployment)

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= adk-rg-westus2
AZ_ACR_NAME ?= adkacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_APP_SERVICE_NAME ?= adk-app-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_PLAN_NAME ?= adk-asp
IMAGE_NAME ?= adk-image
IMAGE_TAG ?= latest

# Credentials and Project Info
PROJECT_ID := $(shell cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION := us-central1
GEMINI_API_KEY := $(shell cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all clean test deploy run endpoint status az-status az-logs docker-build az-login acr-create acr-login push-acr az-deploy deploy-azure

all: run

# Run the app locally (assuming adk is installed)
run:
	@echo "Running ADK Web UI locally..."
	adk web . --host 0.0.0.0 --port 8080

clean:
	@echo "Cleaning up generated images and temporary files..."
	find . -name "*.log" -delete 2>/dev/null || true
	find images -name "*.png" -delete 2>/dev/null || true
	find output/images -name "*.png" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	@echo "Clean completed."

# Build the Docker image
docker-build:
	@echo "Building the Docker image..."
	docker build -t $(IMAGE_NAME) .

# Azure Login
az-login:
	@echo "Logging in to Azure..."
	az login

# ACR related targets
acr-create:
	@echo "Ensuring Resource Group $(AZ_RESOURCE_GROUP) exists..."
	az group create --name $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION)
	@echo "Checking if ACR $(AZ_ACR_NAME) exists..."
	az acr show --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating ACR $(AZ_ACR_NAME)..." && \
		az acr create --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --sku Basic)

acr-login:
	@echo "Logging in to Azure Container Registry..."
	az acr login --name $(AZ_ACR_NAME)

push-acr: docker-build acr-create acr-login
	@echo "Pushing the Docker image to ACR..."
	docker tag $(IMAGE_NAME) $(FULL_IMAGE_NAME)
	docker push $(FULL_IMAGE_NAME)

# Deploy to Azure App Service
deploy: deploy-azure

deploy-azure: push-acr
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
	@az webapp config appsettings set --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --settings \
		PORT=8080 \
		WEBSITES_PORT=8080 \
		GOOGLE_CLOUD_PROJECT="$(PROJECT_ID)" \
		GOOGLE_CLOUD_LOCATION="$(GOOGLE_CLOUD_LOCATION)" \
		GOOGLE_GENAI_USE_VERTEXAI="False" \
		VERTEX_AI="FALSE" \
		VERTEX="no" \
		GOOGLE_API_KEY="$(GEMINI_API_KEY)" \
		GEMINI_API_KEY="$(GEMINI_API_KEY)" \
		MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
		ADK_DISABLE_LOCAL_STORAGE=1
	@echo "Deployment complete. Visit: http://$$(az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "defaultHostName" --output tsv)"

status: az-status

az-status:
	@echo "Checking Azure App Service status for $(AZ_APP_SERVICE_NAME)..."
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:state, Host:defaultHostName}" --output table 2>/dev/null || echo "App Service $(AZ_APP_SERVICE_NAME) not found."

az-logs:
	@echo "Fetching logs for $(AZ_APP_SERVICE_NAME)..."
	@az webapp log tail --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP)

endpoint:
	@echo "--- Azure Endpoint ---"
	@az webapp show --name $(AZ_APP_SERVICE_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "defaultHostName" --output tsv 2>/dev/null || echo "N/A"
