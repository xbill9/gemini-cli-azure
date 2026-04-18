#!/bin/bash
# aca/deploy-fabric.sh - Deploy to ACA and prepare Microsoft Fabric Manifest

set -e

# Run standard ACA deployment and capture output
echo "Starting Azure Container Apps deployment..."
DEPLOY_OUTPUT=$(./aca/deploy-aca.sh)
echo "$DEPLOY_OUTPUT"

# Extract the App FQDN from the output
APP_FQDN=$(echo "$DEPLOY_OUTPUT" | grep "Public App URL:" | sed 's/Public App URL: https:\/\///')

if [ -z "$APP_FQDN" ]; then
    echo "ERROR: Failed to extract Public App URL from deployment output."
    exit 1
fi

echo "--- Microsoft Fabric Integration ---"
echo "Detected App FQDN: $APP_FQDN"

# Get Client ID (Optional, placeholder if not set)
AZ_CLIENT_ID=${AZ_CLIENT_ID:-"YOUR_ENTRA_APP_ID"}

# Generate WorkloadManifest.xml from template
MANIFEST_FILE="aca/WorkloadManifest.xml"
cp aca/WorkloadManifest.xml.template "$MANIFEST_FILE"
sed -i "s/{{APP_FQDN}}/$APP_FQDN/g" "$MANIFEST_FILE"
sed -i "s/{{AZ_CLIENT_ID}}/$AZ_CLIENT_ID/g" "$MANIFEST_FILE"

echo "Microsoft Fabric Workload Manifest generated: $MANIFEST_FILE"
echo "================================================================="
echo "NEXT STEPS FOR MICROSOFT FABRIC:"
echo "1. Register your backend App in Microsoft Entra ID (if not done)."
echo "2. Add the 'Fabric.Extend' scope to your App registration."
echo "3. Upload the generated '$MANIFEST_FILE' to the Fabric Admin Portal."
echo "   (Settings -> Admin portal -> Workloads -> Upload manifest)"
echo "4. For local testing, use the Fabric DevGateway pointing to:"
echo "   https://$APP_FQDN"
echo "================================================================="
