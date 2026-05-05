#!/bin/bash

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "Error: No active gcloud account found."
    echo "Please run 'gcloud auth login' and try again."
    exit 1
fi

if [ -f "$HOME/project_id.txt" ]; then
    PROJECT_ID=$(cat "$HOME/project_id.txt")
else
    read -p "Enter Project ID: " PROJECT_ID
    echo "$PROJECT_ID" > "$HOME/project_id.txt"
fi

if [ -f "$HOME/azure.key" ]; then
    AZURE_AI_API_KEY=$(cat "$HOME/azure.key")
else
    read -p "Enter Azure KEY: " AZURE_AI_API_KEY
    echo "$AZURE_AI_API_KEY" > "$HOME/azure.key"
fi

gcloud config set project "$PROJECT_ID"

# enable services


if [ -z "$CLOUD_SHELL" ]; then
    if ! gcloud auth application-default print-access-token > /dev/null 2>&1; then
        echo "ADC expired or not found. Initializing login..."
        gcloud auth application-default login
    else
        echo "ADC is valid."
    fi
fi

# Use the Google Cloud SDK bundled Python 3.13
PYTHON_CMD=/usr/lib/google-cloud-sdk/platform/bundledpythonunix/bin/python3
if [ ! -f "$PYTHON_CMD" ]; then
  PYTHON_CMD=python3
fi

if [ ! -f ".requirements_installed" ]; then
    $PYTHON_CMD -m pip install -r requirements.txt
    touch .requirements_installed
fi

echo "Environment setup"
cat .env

echo "Cloud Login"
gcloud auth list

echo "ADK update"
$PYTHON_CMD -m pip install google-adk --upgrade
$PYTHON_CMD -m google.adk.cli --version
