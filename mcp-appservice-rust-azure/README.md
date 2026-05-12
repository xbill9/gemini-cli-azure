# mcp-appservice-rust-azure

A Rust-based Model Context Protocol (MCP) server designed for deployment on Azure App Service, utilizing streaming HTTP.

## Overview

This project implements an MCP server that provides tools to LLM agents. It is built with Rust using the `rmcp` library and the `axum` web framework. The server supports streaming HTTP (SSE) for efficient, long-lived connections.

## Features

- **Rust Implementation**: Built with high-performance, safe Rust code (2024 edition).
- **App Service Deployment**: Pre-configured for Azure App Service (Web App for Containers).
- **Streaming HTTP**: Uses the Model Context Protocol streaming transport for low-latency communication.
- **Dockerized**: Ready for containerized deployment.
- **Health Checks**: Built-in `/health` endpoint for Azure health probes.

## Tools

This MCP server provides the following tools:

- **`greeting`**: A simple tool that echoes back a message.
  - **Parameters**:
    - `message` (string): The message to echo.
  - **Returns**: A string containing the greeting and the original message.

## Configuration

The server can be configured using the following environment variables:

- `PORT`: The port the server will listen on (default: `8080`).
- `ALLOWED_HOSTS`: A comma-separated list of allowed hostnames for DNS rebinding protection. Set to `*` to disable this check (default: `*` in App Service deployment).

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (latest stable)
- [Docker](https://docs.docker.com/get-docker/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

## Getting Started

### Local Development

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/xbill9/gemini-cli-azure.git
    cd mcp-appservice-rust-azure
    ```

2.  **Build the project**:
    ```bash
    make build
    ```

3.  **Run the server**:
    ```bash
    make run
    ```
    The server will start on `http://localhost:8080`.

4.  **Test the server**:
    ```bash
    make test
    ```

### Deployment to Azure App Service

To deploy the application to Azure App Service:

1.  **Login to Azure**:
    ```bash
    make az-login
    ```

2.  **Deploy**:
    ```bash
    make deploy
    ```

This will build the Docker image, push it to Azure Container Registry (ACR), create the App Service Plan and Web App (if they don't exist), configure Managed Identity for ACR access, and deploy the image.

### Monitoring

Check the status of your deployment:
```bash
make appservice-status
```

To monitor logs from the App Service:
```bash
make appservice-logs
```

## Makefile Targets

- `make run`: Starts the server locally.
- `make build`: Compiles the project.
- `make test`: Runs unit tests.
- `make docker-build`: Builds the Docker image locally.
- `make deploy`: Full deployment pipeline to Azure App Service.
- `make appservice-status`: Displays the status and URL of the service.
- `make appservice-logs`: Follows the logs of the running app.
- `make destroy`: Deletes the resource group and all associated resources.

## License

MIT
