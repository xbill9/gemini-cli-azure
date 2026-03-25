# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the project and assist in development.

## Project Overview

This is a **Python-based Model Context Protocol (MCP) server** using the `FastMCP` class from the `mcp` SDK, deployed as an **Azure Function**. It is designed to expose tools over HTTP for integration with MCP clients (such as Claude Desktop or Gemini extensions).

## Key Technologies

*   **Language:** Python 3.11 (as per `Makefile` deployment configuration)
*   **SDK:** `mcp` (Model Context Protocol SDK)
*   **Library:** `FastMCP` (for simplified server creation)
*   **Platform:** Azure Functions (V2 Python Programming Model)
    *   **Note:** Use `stateless_http=True` in `mcp.http_app()` to ensure compatibility with Azure Functions' scaling and instance recycling.
*   **Logging:** `python-json-logger` for structured logging to stderr
*   **Dependency Management:** `pip` / `requirements.txt`

Azure Functions:
https://github.com/Azure-Samples/azure-functions-flex-consumption-samples
https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-mcp?pivots=programming-language-csharp

## Project Structure

* `function_app.py`: The entry point of the application for Azure Functions. Initializes the `FastMCP` server ("hello-world-server") and exports an `AsgiFunctionApp`.
* `host.json`: Azure Functions host configuration.
* `local.settings.json`: Local settings for Azure Functions Core Tools.
* `requirements.txt`: Python dependencies.
* `Makefile`: Development shortcuts (test, lint, clean, deploy, status, az-destroy).
* `Dockerfile`: Container configuration (optional, not used for main deployment).

## Development Setup

1.  **Create and activate a virtual environment:**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```

2.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

## Running the Server

### Locally with Python
```bash
python function_app.py
```

### Locally with Azure Functions Core Tools
```bash
func start
```

*Note: This is an MCP server running over HTTP and should be started before an MCP client attempts to connect.*

## Endpoints

- **`/health`**: Standard HTTP health check endpoint (`GET`).
- **`/ping`**: A simple Azure Function endpoint for connectivity testing (`GET`).
- **`/*`**: All other routes are handled by the `FastMCP` ASGI application.

## Deployment

The project is configured for deployment to **Azure Functions** using Zip deploy.

### Deployment Prerequisites
- Azure CLI installed and logged in (`az login`).
- `zip` utility installed (used in Makefile).

### Deployment Steps
1.  **Deploy to Azure:** `make deploy`
    - This command handles Resource Group, Storage Account, and Function App creation, followed by Zip deployment.
2.  **View Logs:** `make az-logs`
3.  **Check Status:** `make status`
4.  **Get Endpoint:** `make endpoint`
5.  **Cleanup Resources:** `make az-destroy`
    - This command deletes the entire Resource Group and all associated resources.

## Python MCP Developer Resources

*   **MCP Python SDK (GitHub):** [https://github.com/mcp-protocol/mcp-python-sdk](https://github.com/mcp-protocol/mcp-python-sdk)
*   **FastMCP Documentation:** [https://gofastmcp.com/](https://gofastmcp.com/)
*   **Azure Functions Python Developer Guide:** [https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python)
