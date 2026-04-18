# Makefile for Biometric Security System - Azure Container Apps & Functions

.PHONY: clean test lint deploy run endpoint frontend mock adk azure-status az-destroy status deploy-func func-status func-destroy func-endpoint

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

lint:
	ruff check .
	ruff format --check .
	cd frontend && npm run lint

frontend:
	cd frontend && npm install && npm run build

# Azure Deployment (Container Apps)
deploy:
	./deploy.sh

# Azure Deployment (Functions)
deploy-func:
	chmod +x deploy-func.sh
	./deploy-func.sh

status: azure-status

azure-status:
	@az containerapp show --name biometric-scout-app --resource-group aca --query "{Name:name, State:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "Container App not found."

func-status:
	@az functionapp show --name biometric-scout-func --resource-group func-rg --query "{Name:name, State:properties.state, URL:defaultHostName}" --output table 2>/dev/null || echo "Function App not found."

az-destroy:
	@echo "Destroying resource group: aca..."
	@az group delete --name aca --yes --no-wait
	@echo "Deletion command sent successfully."

func-destroy:
	@echo "Destroying resource group: func-rg..."
	@az group delete --name func-rg --yes --no-wait
	@echo "Deletion command sent successfully."

endpoint:
	@az containerapp show --name biometric-scout-app --resource-group aca --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "Container App not found."

func-endpoint:
	@az functionapp show --name biometric-scout-func --resource-group func-rg --query "defaultHostName" -o tsv 2>/dev/null || echo "Function App not found."

run:
	. ./biosync.sh

mock:
	. ./mock.sh

adk:
	. ./runadk.sh

testadk:
	. ./testadk.sh
