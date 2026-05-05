import os

import uvicorn
from fastapi import FastAPI
from google.adk.cli.fast_api import get_fast_api_app

# The directory where this main.py is located
# ADK will scan all subdirectories for 'agent.py' files containing 'root_agent'
AGENT_DIR = os.path.dirname(os.path.abspath(__file__))

# Using SQLite for session storage as it's self-contained for Lightsail
SESSION_SERVICE_URI = "sqlite+aiosqlite:///./sessions.db"

# CORS configuration
ALLOWED_ORIGINS = ["*"]

# Serve the ADK Web UI (optional but helpful for testing)
SERVE_WEB_INTERFACE = True

# Initialize the FastAPI app via ADK's built-in helper
app: FastAPI = get_fast_api_app(
    agents_dir=AGENT_DIR,
    session_service_uri=SESSION_SERVICE_URI,
    allow_origins=ALLOWED_ORIGINS,
    web=SERVE_WEB_INTERFACE,
)

if __name__ == "__main__":
    # Lightsail / App Runner / Lambda typically provide a PORT environment variable
    port = int(os.environ.get("PORT", 8080))
    print("--- Starting ADK Agent Server ---")
    print(f"Web UI: http://localhost:{port}/web")
    uvicorn.run(app, host="0.0.0.0", port=port)
