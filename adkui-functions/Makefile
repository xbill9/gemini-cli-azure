# Makefile for ADK Comic Pipeline (Azure Container Instance Deployment)

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= adk-rg-westus2
AZ_ACR_NAME ?= adkacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_CONTAINER_GROUP_NAME ?= adk-container-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= adk-image
IMAGE_TAG ?= latest

# Credentials and Project Info
PROJECT_ID := $(shell cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION := us-central1
GEMINI_API_KEY := $(shell cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all clean test deploy run endpoint status logs az-status-aci az-logs-aci az-destroy-aci docker-build az-login acr-create acr-login push-acr az-deploy-aci deploy-aci az-destroy destroy az-destory

all: run

# Run the app locally (assuming adk is installed)
run:
	@echo "Running ADK Web UI locally..."
	adk web . --host 0.0.0.0 --port 8080

destroy: az-destroy

az-destory: destroy

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

# Deploy to Azure Container Instance (Default)
deploy: deploy-aci

deploy-aci: az-deploy-aci

az-deploy-aci: push-acr
	@echo "Enabling ACR admin user..."
	@az acr update --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --admin-enabled true
	@echo "Waiting 30 seconds for ACR credentials to propagate..."
	@sleep 30
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
		--environment-variables \
			PORT=8080 \
			GOOGLE_CLOUD_PROJECT="$(PROJECT_ID)" \
			GOOGLE_CLOUD_LOCATION="$(GOOGLE_CLOUD_LOCATION)" \
			GOOGLE_GENAI_USE_VERTEXAI="False" \
			VERTEX_AI="FALSE" \
			VERTEX="no" \
			GOOGLE_API_KEY="$(GEMINI_API_KEY)" \
			GEMINI_API_KEY="$(GEMINI_API_KEY)" \
			MODEL_ID="gemini-2.5-flash-native-audio-preview-12-2025" \
			ADK_DISABLE_LOCAL_STORAGE=1
	@echo "Deployment complete. Endpoint: http://$$(az container show --resource-group $(AZ_RESOURCE_GROUP) --name $(AZ_CONTAINER_GROUP_NAME) --query ipAddress.fqdn -o tsv):8080"

status: az-status-aci

az-status-aci:
	@echo "Checking Azure Container Instance status for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" --output table 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."

logs: az-logs-aci

az-logs-aci:
	@echo "Fetching logs for $(AZ_CONTAINER_GROUP_NAME)..."
	@az container logs --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

endpoint:
	@echo "--- Azure Container Instance Endpoint ---"
	@az container show --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "N/A"

az-destroy: az-destroy-aci
	@echo "Destroying Azure Resource Group $(AZ_RESOURCE_GROUP)..."
	az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Resource Group deletion initiated. This may take a few minutes."

az-destroy-aci:
	@echo "Deleting Azure Container Instance $(AZ_CONTAINER_GROUP_NAME)..."
	@az container delete --name $(AZ_CONTAINER_GROUP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes 2>/dev/null || echo "Container Group $(AZ_CONTAINER_GROUP_NAME) not found."
