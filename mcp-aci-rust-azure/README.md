# mcp-aci-rust-azure

A Rust-based Model Context Protocol (MCP) server designed for deployment on Azure Container Instances (ACI), utilizing streaming HTTP.

## Features

- **Model Context Protocol (MCP)**: Implements the MCP specification for seamless integration with AI agents.
- **Streaming HTTP**: Uses `rmcp` and Axum for high-performance, streaming-capable HTTP transport.
- **Rust (2024 Edition)**: Leverages the latest Rust features for safety and concurrency.
- **ACI Deployment**: Pre-configured for Azure Container Instances (ACI).
- **Health Checks**: Standard `/health` endpoint for container health probes.
- **Graceful Shutdown**: Handles OS signals for clean shutdowns.

## Getting Started

### Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (2024 Edition)
- [Docker](https://www.docker.com/get-started)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### Local Development

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/xbill9/gemini-cli-azure
    cd mcp-aci-rust-azure
    ```

2.  **Run locally**:
    ```bash
    make run
    ```
    The server will be available at `http://localhost:8080`.

3.  **Run tests**:
    ```bash
    make test
    ```

### Configuration

The application can be configured via environment variables:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `PORT` | The port the server listens on. | `8080` |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hostnames/IPs for DNS rebinding protection. Use `*` to disable (default behavior if unset). | `0.0.0.0,localhost,127.0.0.1` |
| `RUST_LOG` | Logging filter level. | `info,mcp_aci_rust_azure=debug,rmcp=debug` |

### Deployment to ACI

To deploy the application to Azure ACI:

1.  **Login to Azure**:
    ```bash
    make az-login
    ```

2.  **Deploy**:
    ```bash
    make deploy
    ```
    This will build the Docker image, push it to Azure Container Registry (ACR), and deploy the container to ACI.

3.  **Check Status**:
    ```bash
    make az-status
    ```

4.  **Monitor Logs**:
    ```bash
    make logs
    ```

## Makefile Commands

- `make build`: Build the project for development.
- `make run`: Run the project locally.
- `make test`: Run unit tests.
- `make deploy`: Full deployment pipeline to ACI.
- `make endpoint`: Fetch the public FQDN of the ACI instance.
- `make logs`: Tail logs from the ACI container.
- `make destroy`: Clean up all Azure resources.

## License

MIT
