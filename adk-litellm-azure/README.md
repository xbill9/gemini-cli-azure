# Azure AI Foundry & ADK Agents

[![Azure](https://img.shields.io/badge/Azure-AI%20Foundry-0078D4?style=flat&logo=microsoft-azure)](https://azure.microsoft.com/en-us/products/ai-foundry)
[![ADK](https://img.shields.io/badge/ADK-Agent%20Development%20Kit-4285F4?style=flat&logo=google-cloud)](https://github.com/google/agent-development-kit)
[![Model](https://img.shields.io/badge/Model-Phi--4--mini-blue)](https://azure.microsoft.com/en-us/blog/introducing-phi-4-mini-microsofts-newest-small-language-model/)

## Overview
This project is an Azure-based agent ecosystem that leverages **Azure AI Foundry** and the **Agent Development Kit (ADK)** for building and orchestrating multi-agent systems. It features a specialized agent powered by **Phi-4-mini**, Microsoft's high-performance Small Language Model (SLM).

The ecosystem is built for agility and scalability, using **LiteLLM** as a universal model router and **FastAPI** to serve agents with a built-in Web UI.

---

## 🟢 System Status
*   **Azure AI Stack:** ONLINE (Azure AI Foundry, `phi-4-mini`)
*   **ADK Agents:** ACTIVE (Serving `azure_agent`)
*   **Web UI:** ENABLED (Available on `http://localhost:8080/web`)

---

## 📂 Repository Structure

-   `agents/`: Core agent implementations.
    -   `main.py`: FastAPI entrypoint and agent scanner.
    -   `azure/agent.py`: Phi-4-mini powered agent definition.
    -   `litellm_config.yaml`: Centralized model routing configuration.
-   `setup-azure-phi.sh`: Automated infrastructure provisioning (RG, Workspace, Endpoint).
-   `get-azure-phi-creds.sh`: Discovery script to sync Azure credentials to `.env`.
-   `init.sh`: Environment initialization and dependency installation.
-   `Makefile`: Shortcuts for common tasks (install, run, lint, clean).

---

## 🚀 Quick Start

### 1. Azure Infrastructure Setup
Ensure your Azure CLI is logged in and run the automated setup script to create the necessary resources and deploy Phi-4-mini:
```bash
az login
./setup-azure-phi.sh
```

### 2. Credential Synchronization
If the resources already exist, use the discovery script to retrieve credentials and update your environment:
```bash
./get-azure-phi-creds.sh
```

### 3. Run the Agents
Install dependencies and start the FastAPI server:
```bash
make install
make run
```
Access the interactive Web UI at [http://localhost:8080/web](http://localhost:8080/web).

---

## 🛠 Technical Details

### Agent Development Kit (ADK)
The **Agent Development Kit (ADK)** provides the orchestration layer. Agents are defined in `agents/` and automatically discovered by `main.py`.

### Azure AI Foundry Integration
We use **Phi-4-mini** serverless endpoints for low-latency, cost-effective inference.
- **Provider:** `azure_ai`
- **Model:** `azure_ai/phi-4-mini`
- **Router:** LiteLLM (unified API interface).
- **Automation:** `get-azure-phi-creds.sh` is optimized to discover `serverless-endpoint` resources automatically.

### Environment Variables
The following variables are required and managed by the setup scripts:
- `AZURE_AI_API_KEY`: Scoring key for the serverless endpoint.
- `AZURE_AI_API_BASE`: Scoring URI for the Azure AI endpoint.
- `AZURE_MODEL`: The model identifier (default: `azure_ai/phi-4-mini`).
