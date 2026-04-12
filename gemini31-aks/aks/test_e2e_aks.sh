#!/bin/bash
set -e

SERVICE_NAME="biometric-scout-app"

echo "Getting AKS LoadBalancer IP..."
IP=$(kubectl get svc ${SERVICE_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)

if [ -z "$IP" ]; then
    echo "ERROR: Could not find ${SERVICE_NAME} LoadBalancer IP. Is it deployed to AKS?"
    exit 1
fi

echo "Testing Biometric Scout App at http://$IP..."

# Test root (frontend)
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP)
if [ "$RESPONSE" -eq 200 ]; then
    echo "SUCCESS: Frontend is accessible (HTTP 200)"
else
    echo "FAILURE: Frontend returned HTTP $RESPONSE"
    exit 1
fi

echo "AKS E2E Test Completed successfully!"
