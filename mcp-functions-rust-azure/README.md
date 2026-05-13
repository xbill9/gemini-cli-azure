# mcp-functions-rust-azure

A streaming HTTP Model Context Protocol (MCP) server written in Rust, optimized for deployment on **Azure Functions** as a Custom Handler.

## Features

*   **Rust 2024 Edition:** Leverages the latest Rust features for performance and safety.
*   **Model Context Protocol (MCP):** Implements the latest MCP spec via the [`rmcp`](https://github.com/modelcontextprotocol/rust-sdk) library.
*   **Streaming HTTP:** Support for long-lived Server-Sent Events (SSE) connections for real-time tool interactions.
*   **Azure Functions Integration:** Designed as a Custom Handler, allowing you to run a full Axum web server on Azure Functions.
*   **Containerized:** Dockerized for consistent deployment across environments.
*   **Managed Identity:** Securely pulls images from Azure Container Registry (ACR) using Managed Identity.

## Getting Started

### Prerequisites

*   [Rust](https://www.rust-lang.org/tools/install) (2024 Edition)
*   [Docker](https://docs.docker.com/get-docker/)
*   [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
*   [Make](https://www.gnu.org/software/make/)

### Local Development

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/xbill9/gemini-cli-azure
    cd mcp-functions-rust-azure
    ```

2.  **Build and Run:**
    ```bash
    make build
    make run
    ```
    The server will start on `http://localhost:8080`.

3.  **Test the health endpoint:**
    ```bash
    curl http://localhost:8080/health
    ```

4.  **Test the greeting tool (Local):**
    MCP clients (like Claude Desktop or Gemini CLI) can connect to the server using SSE.

### Deployment to Azure

1.  **Login to Azure:**
    ```bash
    make az-login
    ```

2.  **Deploy everything:**
    ```bash
    make deploy
    ```
    This command will:
    *   Create a Resource Group.
    *   Create an Azure Container Registry (ACR).
    *   Build and push the Docker image to ACR.
    *   Create a Storage Account (required for Functions).
    *   Create an App Service Plan (Linux).
    *   Create and configure the Azure Function App.
    *   Set up Managed Identity for ACR access.

3.  **Get the endpoint:**
    ```bash
    make endpoint
    ```

## Project Structure

*   `src/main.rs`: The main entry point, tool definitions, and server logic.
*   `host.json`: Azure Functions configuration for the Custom Handler.
*   `mcp/function.json`: Defines the HTTP trigger and routing for the MCP server.
*   `Dockerfile`: Multi-stage build for a minimal deployment container.
*   `Makefile`: Automation for build, test, and deployment.

## Implemented Tools

### `greeting`
A simple tool that echoes back a message.
*   **Parameters:** `message` (string)
*   **Returns:** `Hello World MCP! {message}`

## Configuration

*   `FUNCTIONS_CUSTOMHANDLER_PORT`: The port the server listens on (provided by Azure Functions).
*   `ALLOWED_HOSTS`: Comma-separated list of allowed hostnames for DNS rebinding protection (default: `*`).

## License

MIT
