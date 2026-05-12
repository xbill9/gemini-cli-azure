# mcp-aks-rust-azure

A Rust-based Model Context Protocol (MCP) server designed for deployment on Azure Kubernetes Service (AKS), utilizing streaming HTTP.

## Overview

This project implements an MCP server that provides tools to LLM agents. It is built with Rust using the `rmcp` library and the `axum` web framework. The server supports streaming HTTP (SSE) for efficient, long-lived connections.

## Features

- **Rust Implementation**: Built with high-performance, safe Rust code (2024 edition).
- **AKS Deployment**: Pre-configured for Azure Kubernetes Service (AKS).
- **Streaming HTTP**: Uses the Model Context Protocol streaming transport for low-latency communication.
- **Dockerized**: Ready for containerized deployment.
- **Health Checks**: Built-in `/health` endpoint for Kubernetes probes.

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (latest stable)
- [Docker](https://docs.docker.com/get-docker/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Getting Started

### Local Development

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/xbill9/gemini-cli-azure.git
    cd mcp-aks-rust-azure
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

### Deployment to AKS

To deploy the application to Azure AKS:

1.  **Login to Azure**:
    ```bash
    make az-login
    ```

2.  **Create ACR and AKS (if needed)**:
    ```bash
    make aks-create
    ```

3.  **Deploy**:
    ```bash
    make deploy
    ```

This will build the Docker image, push it to Azure Container Registry (ACR), and deploy the Kubernetes manifests to the AKS cluster.

### Monitoring

Check the status of your deployment:
```bash
make aks-status
```

Get the public LoadBalancer IP:
```bash
make endpoint
```

To monitor logs from the AKS pods:
```bash
make logs
```

## Makefile Targets

- `make run`: Starts the server locally.
- `make build`: Compiles the project.
- `make test`: Runs unit tests.
- `make docker-build`: Builds the Docker image locally.
- `make deploy`: Full deployment pipeline to AKS.
- `make endpoint`: Displays the public IP of the service.
- `make logs`: Follows the logs of the running pods.
- `make destroy`: Deletes the resource group and all associated resources.

## License

MIT
