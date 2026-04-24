#!/bin/bash
# Startup script for ADK Web Interface
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$SCRIPT_DIR/backend/app/biometric_agent"
echo "GOOGLE_CLOUD_PROJECT=$(cat ~/project_id.txt 2>/dev/null || echo 'your-project-id')" > .env
echo "GOOGLE_CLOUD_LOCATION=us-central1" >> .env
echo "GOOGLE_GENAI_USE_VERTEXAI=False" >> .env
echo "GOOGLE_API_KEY=$GOOGLE_API_KEY" >> .env
echo "GEMINI_API_KEY=$GOOGLE_API_KEY" >> .env
echo "GEMINI_KEY=$GOOGLE_API_KEY" >> .env
echo "MODEL_ID=gemini-3.1-flash-live-preview" >> .env

cd "$SCRIPT_DIR/backend/app"

echo 'connect on http://127.0.0.1:8000/'
echo
adk web --host 0.0.0.0 --allow_origins 'regex:.*'
