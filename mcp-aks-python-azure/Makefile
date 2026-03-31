# Makefile for mcp-aca-python-azure

# Azure Configuration
AZ_LOCATION ?= westus2
AZ_RESOURCE_GROUP ?= mcp-rg-westus2
AZ_ACR_NAME ?= mcpacr$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)v2
AZ_CONTAINER_APP_NAME ?= mcp-app-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACA_ENV_NAME ?= mcp-env-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_AKS_CLUSTER_NAME ?= mcp-aks-$(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
IMAGE_NAME ?= mcp-server-image
IMAGE_TAG ?= latest

# Derived Azure variables
ACR_LOGIN_SERVER := $(AZ_ACR_NAME).azurecr.io
FULL_IMAGE_NAME := $(ACR_LOGIN_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all install run build test lint format type-check status git-status az-status endpoint pull push clean deploy docker-build az-login acr-create acr-login push-acr az-deploy az-logs az-aca-env aks-create aks-get-credentials aks-deploy aks-status aks-destroy

all: install run

# Install dependencies
install:
	pip install -r requirements.txt

# Run the server locally
run:
	python main.py

# Linting
lint:
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

# Format (Placeholder as no specific tool is installed in requirements.txt)
format:
	@echo "Formatting not implemented. Consider adding 'black' or 'ruff'."

# Type checking (Placeholder as no specific tool is installed in requirements.txt)
type-check:
	@echo "Type checking not implemented. Consider adding 'mypy' or 'pyright'."

# Testing (Placeholder)
test:
	@echo "No tests implemented yet."

# Target to show both git and Azure status
status: az-status aks-status
# Target to show git status
git-status:
	@echo "Showing git status..."
	@git status

# Target to show Azure Container App status
az-status:
	@echo "Checking Azure Container App status for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "{Name:name, State:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "Container App $(AZ_CONTAINER_APP_NAME) not found."

# Target to show AKS status
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
	@echo "ACA Endpoint:"
	@az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query "properties.configuration.ingress.fqdn" --output tsv 2>/dev/null || echo "Container App $(AZ_CONTAINER_APP_NAME) not found."
	@echo "AKS Endpoint:"
	@kubectl get svc mcp-server-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "AKS service not found or IP not yet assigned."

# Target to pull latest changes from git
pull:
	@echo "Pulling latest changes from git..."
	@git pull

# Target to push changes to git
push:
	@echo "Pushing changes to git..."
	@git push

# Build the Docker image
docker-build:
	@echo "Building the Docker image..."
	@docker build -t $(IMAGE_NAME) .

# Azure Login
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
	@echo "Pushing the Docker image to ACR..."
	@docker tag $(IMAGE_NAME) $(FULL_IMAGE_NAME)
	@docker push $(FULL_IMAGE_NAME)

# Deploy to Azure Kubernetes Service (AKS)
deploy: aks-deploy

az-aca-env:
	@echo "Checking if Container App Environment $(AZ_ACA_ENV_NAME) exists..."
	@az containerapp env show --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) > /dev/null 2>&1 || \
		(echo "Creating Container App Environment $(AZ_ACA_ENV_NAME)..." && \
		az containerapp env create --name $(AZ_ACA_ENV_NAME) --resource-group $(AZ_RESOURCE_GROUP) --location $(AZ_LOCATION))

az-deploy: push-acr az-aca-env
	@echo "Enabling ACR admin user..."
	@az acr update --name $(AZ_ACR_NAME) --resource-group $(AZ_RESOURCE_GROUP) --admin-enabled true
	@echo "Deploying to Azure Container App..."
	@AZ_ACR_USERNAME=$$(az acr credential show --name $(AZ_ACR_NAME) --query "username" -o tsv) && \
	AZ_ACR_PASSWORD=$$(az acr credential show --name $(AZ_ACR_NAME) --query "passwords[0].value" -o tsv) && \
	az containerapp create \
		--name $(AZ_CONTAINER_APP_NAME) \
		--resource-group $(AZ_RESOURCE_GROUP) \
		--environment $(AZ_ACA_ENV_NAME) \
		--image $(FULL_IMAGE_NAME) \
		--target-port 8080 \
		--ingress external \
		--registry-server $(ACR_LOGIN_SERVER) \
		--registry-username $$AZ_ACR_USERNAME \
		--registry-password $$AZ_ACR_PASSWORD \
		--env-vars PORT=8080 \
		--cpu 0.5 \
		--memory 1.0Gi \
		--min-replicas 1 \
		--max-replicas 1
	@echo "Deployment complete. Endpoint: https://$$(az containerapp show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP) --query properties.configuration.ingress.fqdn -o tsv)"

az-logs:
	@echo "Fetching logs for $(AZ_CONTAINER_APP_NAME)..."
	@az containerapp logs show --name $(AZ_CONTAINER_APP_NAME) --resource-group $(AZ_RESOURCE_GROUP)

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

aks-destroy:
	@echo "Deleting AKS cluster $(AZ_AKS_CLUSTER_NAME)..."
	@az aks delete --name $(AZ_AKS_CLUSTER_NAME) --resource-group $(AZ_RESOURCE_GROUP) --yes --no-wait

# Target to delete all Azure resources by deleting the resource group
az-destroy:
	@echo "Deleting Resource Group $(AZ_RESOURCE_GROUP) and all associated resources..."
	@az group delete --name $(AZ_RESOURCE_GROUP) --yes --no-wait
	@echo "Deletion of $(AZ_RESOURCE_GROUP) initiated in the background."


.PHONY: clean
clean:
	@echo "Cleaning up..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type d -name ".pyte*" -exec rm -rf {} +
	@find . -type d -name ".mypy*" -exec rm -rf {} +
	@rm -rf .venv
