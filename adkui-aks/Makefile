# Makefile for ADK Comic Pipeline (Azure AKS Deployment)

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= adk-rg-westus2
HOSTNAME_ID := $(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME ?= adkacr$(HOSTNAME_ID)v2
AZ_AKS_CLUSTER_NAME ?= adk-aks-$(HOSTNAME_ID)
IMAGE_NAME ?= adk-image
IMAGE_TAG ?= latest

# Credentials and Project Info
PROJECT_ID := $(shell cat ~/project_id.txt 2>/dev/null || echo "unknown-project")
GOOGLE_CLOUD_LOCATION := us-central1
GEMINI_API_KEY := $(shell cat ${HOME}/gemini.key 2>/dev/null || echo "")

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all clean test deploy run endpoint status aks-status aks-logs docker-build az-login acr-create acr-login push-acr deploy-aks aks-destroy

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

# Deploy to Azure Kubernetes Service (AKS)
deploy: deploy-aks

deploy-aks: ./deploy-aks.sh
	./deploy-aks.sh

status: aks-status

aks-status:
	@echo "Checking AKS Deployment status..."
	@kubectl get deployment adk-app
	@kubectl get pods -l app=adk-app
	@kubectl get service adk-service

logs: aks-logs

aks-logs:
	@echo "Fetching logs for AKS pods..."
	@kubectl logs -l app=adk-app --tail=100 -f

endpoint:
	@echo "--- Azure AKS Endpoint ---"
	@kubectl get svc adk-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A"
	@echo ""

az-destroy: aks-destroy

aks-destroy:
	@echo "Destroying Azure Resource Group $(AZ_RESOURCE_GROUP)..."
	az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Resource Group deletion initiated. This may take a few minutes."
