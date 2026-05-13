# Gemini Workspace for `mcp-appservice-rust-azure`

You are a Rust Developer working with Microsoft Azure.
Follow Rust best practices and idiomatic patterns (2024 edition).

## Project Overview

`mcp-appservice-rust-azure` is a streaming HTTP MCP server written in Rust, designed for deployment on Azure App Service. It uses the `rmcp` library to provide tools to LLM agents via the Model Context Protocol.

### Key Technologies

*   **Language:** Rust (2024 Edition)
*   **MCP Framework:** [`rmcp`](https://github.com/modelcontextprotocol/rust-sdk) (v1.6.0)
*   **Web Framework:** [Axum](https://docs.rs/axum/latest/axum/) (v0.8.9)
*   **Containerization:** Docker
*   **Deployment:** Azure App Service (Web App for Containers)

## Development Workflow

### Useful Commands

- `make run`: Starts the server locally on port 8080.
- `make build`: Compiles the project for development.
- `make test`: Runs unit tests in `src/main.rs`.
- `make clippy`: Runs linting.
- `make fmt`: Formats the code.
- `make start`/`stop`/`status`: Manage background server process.
- `make deploy`: Deploys to Azure App Service.
- `make appservice-status`: Check App Service status and get the endpoint.
- `make appservice-logs`: Tail logs for the App Service.
- `make appservice-destroy`: Delete the App Service and Plan.

### Implementation Details
- **Entry Point:** `src/main.rs` defines the `HelloWorld` struct which implements `ServerHandler`.
- **Streaming HTTP:** The server uses `StreamableHttpService` from `rmcp` to handle long-lived HTTP connections for MCP sessions.
- **Session Management:** Configured with a 1-hour session timeout (`LocalSessionManager`) and 15-second SSE keep-alive.
- **Health Check:** A `/health` endpoint is provided for Azure health probes.
- **Environment Variables:** `PORT` determines the listening port (Configured to 8080 on App Service). `ALLOWED_HOSTS` configures DNS rebinding protection (defaults to `*`).
- **Graceful Shutdown:** Implemented using `tokio::signal`.

## Implemented Tools

- **`greeting`**: Echoes back a provided message.
  - Parameters: `message` (string).
  - Returns: A greeting string.

## Documentation References

- [rmcp Documentation](https://docs.rs/rmcp/latest/rmcp/)
- [Axum Documentation](https://docs.rs/axum/latest/axum/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)

## Tips for Gemini

- **Adding Tools:** Use the `#[tool]` attribute in the `HelloWorld` impl block. Ensure the `tool_router` is correctly initialized in `new()`.
- **Tool Parameters:** Ensure all parameter structs implement `serde::Deserialize` and `schemars::JsonSchema`.
- **Local Sessions:** The `LocalSessionManager` handles MCP session state locally.
- **Tracing:** Use `tracing` for logging. The subscriber is initialized in `main`.
