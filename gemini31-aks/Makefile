# Makefile for Biometric Security System - Azure Kubernetes Service (AKS)

.PHONY: clean test lint deploy run endpoint frontend mock adk az-destroy status e2e deploy-aks status-aks aks-status destroy-aks endpoint-aks test-e2e-aks

clean:
	@echo "Cleaning up logs, caches, and temporary files..."
	find . -type f -name "*.log" -delete 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".adk" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf frontend/dist 2>/dev/null || true
	@echo "Clean completed."

test:
	python -m pytest

e2e: test-e2e-aks

test-e2e-aks:
	@./aks/test_e2e_aks.sh

lint:
	ruff check .
	ruff format --check .
	cd frontend && npm run lint

frontend:
	cd frontend && npm install && npm run build

# Azure Deployment
deploy: deploy-aks

deploy-aks:
	./aks/deploy-aks.sh

status: status-aks

status-aks:
	@echo "Checking AKS Deployment status..."
	@kubectl get deployments
	@kubectl get pods
	@kubectl get services

aks-status: status-aks

destroy-aks:
	@echo "Destroying AKS resources..."
	kubectl delete -f aks/manifests.yaml || true
	kubectl delete secret adk-secrets || true
	kubectl delete secret acr-secret || true

az-destroy:
	@AZ_RESOURCE_GROUP=$${AZ_RESOURCE_GROUP:-"gemini31"}; \
	echo "Destroying Azure Resource Group $$AZ_RESOURCE_GROUP..."; \
	az group delete --name "$$AZ_RESOURCE_GROUP" --yes --no-wait; \
	echo "Resource Group deletion initiated."

endpoint: endpoint-aks

endpoint-aks:
	@echo "--- Azure AKS Endpoint ---"
	@echo "https://biometric-scout-penguinv3.eastus.cloudapp.azure.com"
	@echo ""

run:
	. ./biosync.sh

mock:
	. ./mock.sh

adk:
	. ./runadk.sh

testadk:
	. ./testadk.sh
