# Makefile for Biometric Security System - Azure Container Instances

.PHONY: clean test lint deploy deploy-function run endpoint frontend mock adk azure-status az-destroy status

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

deploy-function:
	chmod +x ./deploy-function.sh
	./deploy-function.sh

status: azure-status

azure-status:
	@echo "--- Azure Container Instances ---"
	@az container show --name biometric-scout-aci --resource-group aci --query "{Name:name, State:instanceView.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" --output table 2>/dev/null || echo "ACI deployment not found."
	@echo "\n--- Azure Functions ---"
	@az functionapp show --name biometric-scout-func --resource-group func-rg --query "{Name:name, State:state, DefaultHostName:defaultHostName}" --output table 2>/dev/null || echo "Functions deployment not found."

az-destroy:
	@echo "Destroying resource groups: aci and func-rg..."
	@az group delete --name aci --yes --no-wait
	@az group delete --name func-rg --yes --no-wait
	@echo "Deletion commands sent successfully."

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
