# Microsoft Fabric MCP Server (Python)

A specialized Model Context Protocol (MCP) server implemented in Python using `FastMCP`, optimized for deployment to **Azure Container Apps** and integration with **Microsoft Fabric**.

## Overview

This project provides a foundational MCP server named `fabric-mcp-server` that can be integrated with Microsoft Fabric custom workloads. It includes built-in support for Azure Authentication (`azure-identity`), making it ready for OneLake and Fabric API interactions.

## Prerequisites

- **Python 3.13+** (Used in Docker image)
- **Azure CLI** with the `containerapp` extension
- **Microsoft Fabric Capacity** (for workload integration)
- **Docker** (for containerization)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd mcp-fabric-python-azure
    ```

2.  **Install dependencies:**
    ```bash
    make install
    ```

## Usage

To run the server locally (authenticated via `az login`):
```bash
python main.py
```
The server will start on `http://0.0.0.0:8080` by default.

### Health Check

- **URL:** `http://localhost:8080/health`
- **Method:** `GET`

## Deployment to Azure (Fabric Backend)

The project uses **Azure Container Apps (ACA)** to host the backend for Fabric workloads.

1.  **Login to Azure:**
    ```bash
    make az-login
    ```

2.  **Deploy to Azure Container Apps:**
    ```bash
    make deploy
    ```
    *This command:*
    - Builds the Docker image.
    - Pushes it to a new/existing Azure Container Registry (ACR).
    - Creates a Container App Environment and the Container App itself.
    - Configures external ingress on port 8080.

3.  **Fabric Registration:**
    - Take the FQDN from `make endpoint`.
    - Register this URL in your Microsoft Fabric Workload manifest.

## Project Structure

- `main.py`: Entry point with `FastMCP` and `azure-identity`.
- `Makefile`: Optimized commands for ACA and Fabric-aligned deployment.
- `Dockerfile`: Multi-stage build for Python 3.13.
- `.gemini/`: Configuration for Gemini CLI and MCP clients.
