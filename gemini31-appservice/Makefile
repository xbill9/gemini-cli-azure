# Makefile for Biometric Security System - Azure Container Apps

.PHONY: clean test lint deploy run endpoint frontend mock adk azure-status az-destroy status

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

# Azure Deployment
deploy:
	./deploy.sh

status: azure-status

azure-status:
	@az webapp show --name biometric-scout-app --resource-group aca --query "{Name:name, State:state, URL:defaultHostName}" --output table

az-destroy:
	@echo "Destroying resource group: aca..."
	@az group delete --name aca --yes --no-wait
	@echo "Deletion command sent successfully."

endpoint:
	@az webapp show --name biometric-scout-app --resource-group aca --query "defaultHostName" -o tsv

run:
	. ./biosync.sh

mock:
	. ./mock.sh

adk:
	. ./runadk.sh

testadk:
	. ./testadk.sh
