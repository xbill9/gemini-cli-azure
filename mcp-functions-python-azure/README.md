# MCP HTTP Python Server for Azure Functions

A simple Model Context Protocol (MCP) server implemented in Python using `FastMCP`, optimized for deployment as an **Azure Function**. This server communicates over `HTTP` and serves as a foundational "Hello World" example for Python-based MCP integrations on Azure.

## Overview

This project provides a basic MCP server named `hello-world-server` that exposes a single tool: `greet`. It leverages the **Azure Functions V2 Python Programming Model** and exports an `AsgiFunctionApp` to handle MCP requests.

## Prerequisites

- **Python 3.11+** (Targeted runtime for Azure Functions)
- `pip` (Python Package Installer)
- **Azure CLI** (for deployment)
- **Azure Functions Core Tools** (optional, for local testing with `func start`)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd mcp-functions-python-azure
    ```

2.  **Set up a virtual environment (recommended):**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate  # On Windows use `.venv\Scripts\activate`
    ```

3.  **Install dependencies:**
    ```bash
    make install
    # Or manually:
    pip install -r requirements.txt
    ```

## Usage

This server is designed to be executed by an MCP client (like Claude Desktop or a Gemini-powered IDE extension) that handles the HTTP communication.

### Running Locally

**Using Python directly:**
```bash
python function_app.py
```
The server will start on `http://0.0.0.0:8080` by default.

**Using Azure Functions Core Tools:**
```bash
func start
```

### Health Check

The server provides a standard HTTP health check endpoint:
- **URL:** `http://localhost:7071/health` (default for `func start`) or `http://localhost:8080/health` (direct run)
- **Method:** `GET`
- **Response:** `{"status": "healthy", "service": "mcp-server"}`

### Configuration for MCP Clients

If you are adding this to an MCP client config (e.g., `claude_desktop_config.json`), the configuration would look something like this:

```json
{
  "mcpServers": {
    "python-hello-world": {
      "url": "http://localhost:8080"
    }
  }
}
```

*Note: Ensure the server is running before the client attempts to connect.*

## Tools

### `greet`
- **Description:** Get a greeting from the local HTTP server.
- **Parameters:**
    - `param` (string): The text or name to echo back.
- **Returns:** The string passed in `param`.

## Deployment to Azure

The project includes a `Makefile` to automate deployment to Azure Functions using **Zip Deploy**.

1.  **Login to Azure:**
    ```bash
    make az-login
    ```

2.  **Deploy to Azure Functions:**
    ```bash
    make deploy
    ```
    *This command performs the following:*
    - Ensures the Resource Group, Storage Account, and Function App exist (`az-setup`).
    - Creates a deployment zip file.
    - Deploys the zip file to the Azure Function App.

3.  **Check Status:**
    ```bash
    make status
    ```

4.  **Monitor Logs:**
    ```bash
    make az-logs
    ```

## Project Structure

- `function_app.py`: Entry point for Azure Functions, exports the `AsgiFunctionApp`.
- `host.json`: Azure Functions global configuration.
- `local.settings.json`: Local settings for Azure Functions Core Tools.
- `requirements.txt`: Python dependencies.
- `Makefile`: Commands for development and deployment.
- `GEMINI.md`: Project-specific context for Gemini.
