# Gemini Workspace for `mcp-aks-rust-azure`

You are a Rust Developer working with Microsoft Azure.
Follow Rust best practices and idiomatic patterns (2024 edition).

## Project Overview

`mcp-aks-rust-azure` is a streaming HTTP MCP server written in Rust, designed for deployment on Azure Kubernetes Service (AKS). It uses the `rmcp` library to provide tools to LLM agents via the Model Context Protocol.

### Key Technologies

*   **Language:** Rust (2024 Edition)
*   **MCP Framework:** [`rmcp`](https://github.com/modelcontextprotocol/rust-sdk) (v1.6.0)
*   **Web Framework:** [Axum](https://docs.rs/axum/latest/axum/) (v0.8.9)
*   **Containerization:** Docker
*   **Deployment:** Azure Kubernetes Service (AKS)

## Development Workflow

### Useful Commands

- `make run`: Starts the server locally on port 8080.
- `make build`: Compiles the project for development.
- `make test`: Runs unit tests in `src/main.rs`.
- `make clippy`: Runs linting.
- `make fmt`: Formats the code.
- `make start`/`stop`/`status`: Manage background server process.
- `make deploy` or `make aks-deploy`: Deploys to Azure AKS.
- `make aks-create`: Create the AKS cluster using `az aks create`.
- `make aks-destroy`: Delete the AKS cluster.
- `make aks-status`: Check AKS deployment and service status.
- `make endpoint`: Get the LoadBalancer IP for the service.
- `make logs`: Tail logs for the AKS pods.

### Implementation Details

- **Entry Point:** `src/main.rs` defines the `HelloWorld` struct which implements `ServerHandler`.
- **Streaming HTTP:** The server uses `StreamableHttpService` from `rmcp` to handle long-lived HTTP connections for MCP sessions.
- **Health Check:** A `/health` endpoint is provided for Kubernetes health probes.
- **Environment Variables:** `PORT` determines the listening port. `ALLOWED_HOSTS` configures DNS rebinding protection.
- **Graceful Shutdown:** Implemented using `tokio::signal`.

## Documentation References

- [rmcp Documentation](https://docs.rs/rmcp/latest/rmcp/)
- [Axum Documentation](https://docs.rs/axum/latest/axum/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Azure Kubernetes Service (AKS) Documentation](https://learn.microsoft.com/en-us/azure/aks/)

## Tips for Gemini

- **Adding Tools:** Use the `#[tool]` attribute in the `HelloWorld` impl block. Ensure the `tool_router` is correctly initialized in `new()`.
- **Tool Parameters:** Ensure all parameter structs implement `serde::Deserialize` and `schemars::JsonSchema`.
- **Local Sessions:** The `LocalSessionManager` handles MCP session state locally.
- **Tracing:** Use `tracing` for logging. The subscriber is initialized in `main`.
