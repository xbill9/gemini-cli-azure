# Makefile for ADK Comic Pipeline

.PHONY: clean test deploy run endpoint status az-destroy

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
	./deploy-aks.sh

deploy-aks:
	./deploy-aks.sh

deploy-azure:
	./deploy-azure.sh

aks-status:
	@echo "Checking AKS status for biometric-scout-aks..."
	@az aks show --name biometric-scout-aks --resource-group biometric-scout-rg --query "{Name:name, State:provisioningState, K8sVersion:kubernetesVersion}" --output table 2>/dev/null || echo "AKS Cluster biometric-scout-aks not found."
	@if kubectl get nodes >/dev/null 2>&1; then \
		echo "Kubernetes Services:"; \
		kubectl get svc biometric-scout-service; \
		echo "Kubernetes Pods:"; \
		kubectl get pods -l app=biometric-scout-app; \
	fi

azure-status:
	@az containerapp show --name biometric-scout-app --resource-group biometric-scout-rg --query "{Name:name, State:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" --output table

status: aks-status

az-destroy:
	@echo "Destroying all Azure resources in biometric-scout-rg..."
	@az group delete --name biometric-scout-rg --yes --no-wait
	@echo "Cleaning up local Kubernetes context..."
	@kubectl config delete-context biometric-scout-aks >/dev/null 2>&1 || true
	@kubectl config delete-cluster biometric-scout-aks >/dev/null 2>&1 || true
	@kubectl config unset users.clusterUser_biometric-scout-rg_biometric-scout-aks >/dev/null 2>&1 || true
	@echo "Deletion command sent and local configuration cleaned up."

endpoint:
	@if [ "$$(kubectl get ingress biometric-scout-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)" ]; then \
		echo "https://$$(kubectl get ingress biometric-scout-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)"; \
	else \
		echo "AKS endpoint not yet assigned."; \
	fi


