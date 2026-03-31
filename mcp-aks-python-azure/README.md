# MCP HTTP Python Server for Azure Kubernetes Service (AKS)

A simple Model Context Protocol (MCP) server implemented in Python using `FastMCP`, optimized for deployment to **Azure Kubernetes Service (AKS)**. This server communicates over `HTTP` and serves as a foundational "Hello World" example for Python-based MCP integrations.

## Overview

This project provides a basic MCP server named `hello-world-server` that exposes a single tool: `greet`. It uses `python-json-logger` for structured logging to stderr, ensuring that the stdout stream remains clean for the MCP protocol JSON-RPC messages.

## Prerequisites

- **Python 3.13+** (Used in Docker image)
- `pip` (Python Package Installer)
- **Azure CLI** (for deployment)
- **Docker** (for containerization)
- **kubectl** (for AKS management)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd mcp-aks-python-azure
    ```

2.  **Set up a virtual environment (recommended):**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate  # On Windows use `.venv\Scripts\activate`
    ```

3.  **Install dependencies:**
    ```bash
    make install
    ```

## Usage

This server is designed to be executed by an MCP client (like Claude Desktop or a Gemini-powered IDE extension) that handles the HTTP communication.

To run the server locally:
```bash
make run
```
The server will start on `http://0.0.0.0:8080` by default.

### Code Quality

Maintain code quality with the following commands:
- **Linting:** `make lint`
- **Testing:** `make test` (placeholder)

### Health Check

The server provides a standard HTTP health check endpoint:
- **URL:** `http://localhost:8080/health`
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

The project includes a `Makefile` to automate deployment to **Azure Kubernetes Service (AKS)** using containers.

1.  **Login to Azure:**
    ```bash
    make az-login
    ```

2.  **Create AKS Cluster (one-time setup):**
    ```bash
    make aks-create
    ```
    *Note: This process may take 10-15 minutes.*

3.  **Deploy to AKS:**
    ```bash
    make deploy
    ```
    *This command performs the following:*
    - Builds the Docker image locally.
    - Pushes the image to Azure Container Registry (ACR).
    - Configures `kubectl` credentials.
    - Applies the Kubernetes manifests (`k8s.yaml`) to the cluster.

4.  **Check Status:**
    ```bash
    make status
    ```

### Alternative Deployment (ACA)

If you prefer **Azure Container Apps (ACA)**, you can use:
```bash
make az-deploy
```

## Project Structure

- `main.py`: Entry point using `FastMCP` to define the server and tools.
- `requirements.txt`: Python dependencies.
- `Makefile`: Commands for build, test, and deployment to Azure.
- `Dockerfile`: Container configuration for deployment.
- `k8s.yaml`: Kubernetes manifests for AKS deployment.
- `GEMINI.md`: Project-specific context for Gemini.
