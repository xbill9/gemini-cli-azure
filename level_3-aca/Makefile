# Makefile for Azure Container Apps Deployment

.PHONY: clean test deploy run mock azure-status az-destroy endpoint frontend

clean:
	@echo "Cleaning up generated images and temporary files..."
	find . -name "*.log" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	@echo "Clean completed."

frontend:
	./frontend.sh

mock:
	./mock.sh

deploy:
	./deploy.sh

azure-status:
	@az containerapp show --name biometric-scout-app --resource-group biometric-scout-rg --query "{Name:name, State:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" --output table

az-destroy:
	@echo "Destroying resource group: biometric-scout-rg..."
	@az group delete --name biometric-scout-rg --yes --no-wait
	@echo "Deletion command sent successfully."

endpoint:
	@az containerapp show --name biometric-scout-app --resource-group biometric-scout-rg --query "properties.configuration.ingress.fqdn" -o tsv
