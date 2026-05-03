#!/bin/bash
# single-container/entrypoint.sh - UNIFIED: Everything in one process

set -e

# Set common environment variables
export PYTHONPATH=$PYTHONPATH:/app:/app/shared:/app/app
export GOOGLE_GENAI_USE_VERTEXAI="False"
export LOG_LEVEL=DEBUG
export GENAI_MODEL=gemini-2.5-flash
export BYPASS_AUTH=true

# Create a logs directory
mkdir -p /app/logs

echo "Diagnostic Information:"
python3 --version
pip list | grep -E "google-adk|a2a-sdk"

echo "Verifying imports..."
python3 -c "from a2a.client import ClientEvent; print('ClientEvent import OK')" || echo "ClientEvent import FAILED"
python3 -c "from google.adk.agents.remote_a2a_agent import DEFAULT_TIMEOUT; print('google.adk OK')" || echo "google.adk FAIL"

echo "Verifying Gemini API connectivity..."
python3 -c "import os; from google import genai; client = genai.Client(api_key=os.getenv('GOOGLE_API_KEY')); response = client.models.generate_content(model='gemini-2.5-flash', contents='hi'); print('Gemini API OK')" || echo "Gemini API connectivity FAILED"

echo "Starting UNIFIED Main App on port 8080..."
# In the unified version, the main app hosts all agents
# and connects to itself for A2A communication.
cd app && python3 main.py
