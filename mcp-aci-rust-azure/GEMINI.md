# Gemini Workspace for `mcp-aci-rust-azure`

You are a Rust Developer working with Microsoft Azure.
Follow Rust best practices and idiomatic patterns (2024 edition).

## Project Overview

`mcp-aci-rust-azure` is a streaming HTTP MCP server written in Rust, designed for deployment on Azure Container Instances (ACI). It uses the `rmcp` library to provide tools to LLM agents via the Model Context Protocol.

### Key Technologies

*   **Language:** Rust (2024 Edition)
*   **MCP Framework:** [`rmcp`](https://github.com/modelcontextprotocol/rust-sdk) (v1.6.0)
*   **Web Framework:** [Axum](https://docs.rs/axum/latest/axum/) (v0.8.9)
*   **Containerization:** Docker
*   **Deployment:** Azure Container Instances (ACI)

## Development Workflow

### Useful Commands

- `make run`: Starts the server locally on port 8080.
- `make build`: Compiles the project for development.
- `make test`: Runs unit tests in `src/main.rs`.
- `make clippy`: Runs linting.
- `make fmt`: Formats the code.
- `make start`/`stop`/`status`: Manage background server process.
- `make deploy` or `make az-deploy`: Deploys to Azure ACI.
- `make az-status`: Check ACI deployment status.
- `make endpoint`: Get the FQDN for the ACI container group.
- `make logs`: Tail logs for the ACI container.
- `make destroy`: Delete the ACI and ACR resources.

### Implementation Details

- **Entry Point:** `src/main.rs` defines the `HelloWorld` struct which implements `ServerHandler`.
- **Streaming HTTP:** The server uses `StreamableHttpService` from `rmcp` to handle long-lived HTTP connections for MCP sessions.
- **Health Check:** A `/health` endpoint is provided for container health probes.
- **Graceful Shutdown:** Implemented using `tokio::signal`.
- **Session Management:** Uses `LocalSessionManager` with a 1-hour session timeout by default.
- **Logging:** Uses `tracing` with a subscriber configured for pretty console output and environment-based filtering.

### Environment Variables

The application can be configured via the following environment variables:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `PORT` | The port the server listens on. | `8080` |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hostnames/IPs for DNS rebinding protection. Use `*` to disable (default behavior if unset). | `0.0.0.0,localhost,127.0.0.1` |
| `RUST_LOG` | Tracing filter level (e.g., `info`, `debug`, `warn`). | `info,mcp_aci_rust_azure=debug,rmcp=debug` |

## Documentation References

- [rmcp Documentation](https://docs.rs/rmcp/latest/rmcp/)
- [Axum Documentation](https://docs.rs/axum/latest/axum/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Azure Container Instances (ACI) Documentation](https://learn.microsoft.com/en-us/azure/container-instances/)

## Tips for Gemini

- **Adding Tools:** 
    1. Define a request struct that implements `serde::Deserialize` and `schemars::JsonSchema`.
    2. Add an `async fn` to the `HelloWorld` `impl` block marked with `#[tool(description = "...")]`.
    3. Use the `Parameters<T>` wrapper for the request argument.
    4. Ensure `self.tool_router` is initialized in `new()` via `Self::tool_router()`.
- **Example Tool (`list_resource_groups`):**
    ```rust
    #[tool(description = "List Azure resource groups")]
    async fn list_resource_groups(&self, _params: Parameters<ListResourceGroupsRequest>) -> String { ... }
    ```
- **JSON Schema:** Use `#[schemars(description = "...")]` on struct fields to provide helpful descriptions for the tool arguments.
- **Tracing:** Use `tracing::info!`, `tracing::debug!`, etc., for logging inside tools.
