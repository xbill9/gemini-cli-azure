# Azure AI Foundry & ADK Agents: Workspace Mandates

This workspace is a specialized environment for building and deploying multi-agent systems using the **Agent Development Kit (ADK)** and **Azure AI Foundry**.

## ☁️ Core Architecture
-   **Framework:** Agent Development Kit (ADK) for Python.
-   **Model Router:** LiteLLM (unified interface for Azure AI).
-   **Storage:** SQLite (via `aiosqlite`) for session and state management.
-   **Interface:** FastAPI-based API server with a built-in Web UI.

### Azure AI Foundry Integration
We primarily use **Phi-4-mini** serverless endpoints for agile agents.
-   **Provider:** `azure_ai` (via LiteLLM).
-   **Default Model:** `azure_ai/phi-4-mini`.
-   **Environment Variables:**
    -   `AZURE_AI_API_KEY`: Authentication key for the serverless endpoint.
    -   `AZURE_AI_API_BASE`: Base URI for the scoring endpoint (e.g., `https://phi-4-mini-endpoint.eastus.inference.ai.azure.com`).

---

## 🛠 Operational Workflows

### 1. Infrastructure Automation
Always prefer using the provided scripts for environment management:
-   `./setup-azure-phi.sh`: Full automation for Resource Group, Workspace, and Serverless Endpoint creation.
-   `./get-azure-phi-creds.sh`: Discovery script to retrieve credentials from an existing workspace and update `.env`.
-   `./init.sh`: Standardizes the local environment (auth, dependencies, version checks).

### 2. Development Workflow (Adding a New Agent)
1.  Create a new directory under `agents/` (e.g., `agents/researcher/`).
2.  Add an `agent.py` file.
3.  Define a `root_agent = LlmAgent(...)` in that file.
4.  The `agents/main.py` scanner will automatically detect and serve the new agent.
5.  Update `agents/litellm_config.yaml` if custom routing or model overrides are required.

---

## 📜 Technical Mandates

-   **Session Persistence:** Always use `sqlite+aiosqlite:///./sessions.db` for the `SESSION_SERVICE_URI` in `main.py` to ensure portability and ease of deployment.
-   **Model Routing:** Use the `azure_ai/` prefix for all Azure AI Foundry models to ensure LiteLLM correctly routes requests to the serverless endpoints.
-   **Credential Safety:** Never hardcode keys. Use `os.getenv` or `os.environ` to retrieve `AZURE_AI_API_KEY` and `AZURE_AI_API_BASE`.
-   **Web UI:** Keep `SERVE_WEB_INTERFACE = True` in `main.py` during development to facilitate rapid testing via the ADK browser interface.

---

## 🧰 Azure CLI Integration Patterns

Use the Azure CLI to manage and inspect the underlying infrastructure:

-   **List Resource Groups:** `az group list -o table`
-   **List ML Workspaces:** `az ml workspace list -o table`
-   **List Serverless Endpoints:** `az ml serverless-endpoint list --workspace-name <ws> --resource-group <rg> -o table`
-   **Get Endpoint Credentials:** `az ml serverless-endpoint get-credentials --name <name> --workspace-name <ws> --resource-group <rg>`

### 🛠 Code Review & Fixes (May 2026)
- **Script Sync:** `get-azure-phi-creds.sh` was updated to correctly target `serverless-endpoint` instead of `online-endpoint`.
- **Enhanced Logging:** `agents/main.py` now provides explicit Web UI URLs on startup.
- **Validation:** Workspace passes `ruff` and `mypy` with zero issues.

### Machine Learning Extension
All `az ml` commands require the `ml` extension. If missing, install via:
`az extension add --name ml`
