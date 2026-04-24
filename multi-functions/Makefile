# Makefile for Biometric Security System - Azure Container Apps & Functions

.PHONY: clean test lint deploy run endpoint frontend mock adk azure-status az-destroy status deploy-func func-status func-destroy func-endpoint e2e-test-functions

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
	chmod +x deploy.sh
	./deploy.sh

# Azure Deployment (Functions)
deploy-func:
	chmod +x deploy-func.sh
	./deploy-func.sh

status: azure-status

azure-status:
	@az containerapp show --name container-app --resource-group multi-functions-east --query "{Name:name, State:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" --output table 2>/dev/null || echo "Container App not found."

func-status:
	@az functionapp show --name azure-functions --resource-group multi-functions-east --query "{Name:name, State:state, URL:defaultHostName}" --output table 2>/dev/null || echo "Function App not found."

az-destroy:
	@echo "Destroying resource group: multi-functions-east..."
	@az group delete --name multi-functions-east --yes --no-wait
	@echo "Deletion command sent successfully."

func-destroy:
	@echo "Destroying resource group: multi-functions-east..."
	@az group delete --name multi-functions-east --yes --no-wait
	@echo "Deletion command sent successfully."

endpoint:
	@az functionapp show --name azure-functions --resource-group multi-functions-east --query "defaultHostName" -o tsv 2>/dev/null || echo "Function App not found."

func-endpoint:
	@az functionapp show --name azure-functions --resource-group multi-functions-east --query "defaultHostName" -o tsv 2>/dev/null || echo "Function App not found."

e2e-test-functions:
	@FUNC_HOST=$$(az functionapp show --name azure-functions --resource-group multi-functions-east --query "defaultHostName" -o tsv 2>/dev/null) && \
	if [ -n "$$FUNC_HOST" ]; then \
		echo "Running E2E test against: $$FUNC_HOST"; \
		python3 test_e2e_func.py $$FUNC_HOST; \
	else \
		echo "Error: Function App not found or not deployed."; \
		exit 1; \
	fi

run:
	. ./biosync.sh

mock:
	. ./mock.sh

adk:
	. ./runadk.sh

testadk:
	. ./testadk.sh
