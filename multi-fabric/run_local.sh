#!/bin/bash

# Kill any existing processes (manual cleanup first)
echo "Stopping any existing agent and server processes..."
pkill -9 -f "unified_app.app" 2>/dev/null || true
pkill -9 -f "vite" 2>/dev/null || true

# Use the current python3 from environment
PYTHON_CMD=$(which python3)

# Set common environment variables for local development
if [ -f ".env" ]; then
  source .env
fi
export PYTHONPATH=$PYTHONPATH:.
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT}"
export GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-us-central1}"
export GOOGLE_GENAI_USE_VERTEXAI="False"
export LOG_LEVEL=DEBUG
export GENAI_MODEL=gemini-2.5-flash
export PORT=8080

# Ensure frontend is built once
if [ ! -d "app/dist" ]; then
  echo "Building frontend..."
  pushd app/frontend > /dev/null
  npm install --no-progress --silent
  npm run build -- --silent
  popd > /dev/null
fi

echo "Starting unified app backend in background with DEBUG logging..."
nohup $PYTHON_CMD -m unified_app.app > backend.log 2>&1 &

echo "Starting frontend dev server (Vite)..."
pushd app/frontend > /dev/null
nohup npm run dev -- --host 0.0.0.0 > ../../frontend.log 2>&1 &
popd > /dev/null

echo "All services started in background."
echo "Frontend: http://localhost:5173"
echo "Backend:  http://localhost:8080"
echo "Logs: backend.log, frontend.log"
