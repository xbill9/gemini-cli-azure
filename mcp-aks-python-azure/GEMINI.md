# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the project and assist in development.

## Project Overview

This is a **Python-based Model Context Protocol (MCP) server** using the `FastMCP` class from the `mcp` SDK. It is designed to expose tools (like `greet`) over HTTP for integration with MCP clients (such as Claude Desktop or Gemini clients).

## Key Technologies

*   **Language:** Python 3.13 (as per Dockerfile)
*   **SDK:** `mcp` (Model Context Protocol SDK)
*   **Library:** `FastMCP` (for simplified server creation)
*   **Logging:** `python-json-logger`
*   **Dependency Management:** `pip` / `requirements.txt`
*   **Linting:** `flake8`

## Project Structure

* `main.py`: The entry point of the application. Initializes the `FastMCP` server ("hello-world-server") and defines tools.
* `requirements.txt`: Python dependencies.
* `Makefile`: Development shortcuts (test, lint, clean, deploy, status).
* `Dockerfile`: Container configuration using `python:3.13-slim`.

## Development Setup

1.  **Create and activate a virtual environment (optional but recommended):**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```

2.  **Install Dependencies:**
    ```bash
    make install
    ```

## Running the Server

The server is configured to run using the `HTTP` transport on `http://0.0.0.0:8080`.

```bash
make run
```

*Note: This is an MCP server running over HTTP and should be started before an MCP client attempts to connect to it.*

## Code Quality

*   **Linting:** `make lint` (runs flake8)
*   **Formatting:** `make format` (placeholder)
*   **Type Checking:** `make type-check` (placeholder)
*   **Testing:** `make test` (placeholder)

## Deployment

The project is configured for deployment to **Azure Container Apps (ACA)** or **Azure Kubernetes Service (AKS)** using Docker containers.

### Deployment Prerequisites
- Azure CLI installed and logged in (`az login`).
- Docker installed locally.
- `kubectl` installed locally (for AKS).

### Deployment Steps (AKS - Default)
1.  **Deploy to Azure:** `make deploy`
    - This command handles ACR creation, image build, push, getting AKS credentials, and applying the `k8s.yaml` manifest.
    - *Note: Ensure the AKS cluster exists first with `make aks-create`.*
2.  **Check Status:** `make status`
3.  **Get Endpoint:** `make endpoint`
4.  **Destroy AKS Cluster:** `make aks-destroy`

### Deployment Steps (ACA)
1.  **Deploy to ACA:** `make az-deploy`
    - This command handles ACR creation, image build, push, Container App Environment creation, and ACA deployment.
2.  **View Logs:** `make az-logs`
3.  **Destroy Resources:** `make az-destroy` (Deletes the resource group)


## Python MCP Developer Resources

*   **MCP Python SDK (GitHub):** [https://github.com/mcp-protocol/mcp-python-sdk](https://github.com/mcp-protocol/mcp-python-sdk)
*   **FastMCP Documentation:** [https://gofastmcp.com/](https://gofastmcp.com/)
*   **`mcp` package on PyPI:** [https://pypi.org/project/mcp/](https://pypi.org/project/mcp/)
