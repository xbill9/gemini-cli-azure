# Makefile for ADK Comic Pipeline

.PHONY: clean test deploy run endpoint az-destroy

clean:
	@echo "Cleaning up generated images and temporary files..."
	find . -name "*.log" -delete 2>/dev/null || true
	find images -name "*.png" -delete 2>/dev/null || true
	find output/images -name "*.png" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	@echo "Clean completed."

frontend:
	cd frontend && npm install && npm run build

mock:
	python mock/mock_server.py

deploy:
	./deploy-azure.sh

deploy-azure:
	./deploy-azure.sh

azure-status:
	@az webapp show --name biometric-scout-app --resource-group biometric-scout-rg --query "state" -o table

az-destroy:
	@echo "Destroying resource group: biometric-scout-rg..."
	@az group delete --name biometric-scout-rg --yes --no-wait
	@echo "Deletion command sent successfully."

endpoint:
	@az webapp show --name biometric-scout-app --resource-group biometric-scout-rg --query "defaultHostName" -o tsv


