# Makefile for Biometric Security System - Azure Container Instances

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
	./deploy-aci.sh

status: azure-status

azure-status:
	@az container show --name biometric-scout-aci --resource-group aci --query "{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" --output table

az-destroy:
	@echo "Destroying resource group: aci..."
	@az group delete --name aci --yes --no-wait
	@echo "Deletion command sent successfully."

endpoint:
	@az container show --name biometric-scout-aci --resource-group aci --query "ipAddress.fqdn" -o tsv

run:
	. ./biosync.sh

mock:
	. ./mock.sh

adk:
	. ./runadk.sh

testadk:
	. ./testadk.sh
