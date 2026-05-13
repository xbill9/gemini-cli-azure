# Gemini Workspace for `mcp-functions-rust-azure`

You are a Rust Developer working with Microsoft Azure.
Follow Rust best practices and idiomatic patterns (2024 edition).

## Project Overview

`mcp-functions-rust-azure` is a streaming HTTP MCP server written in Rust, designed for deployment on Azure Functions (Custom Handler). It uses the `rmcp` library to provide tools to LLM agents via the Model Context Protocol.

### Key Technologies

*   **Language:** Rust (2024 Edition)
*   **MCP Framework:** [`rmcp`](https://github.com/modelcontextprotocol/rust-sdk) (v1.6.0)
*   **Web Framework:** [Axum](https://docs.rs/axum/latest/axum/) (v0.8.9)
*   **Containerization:** Docker
*   **Deployment:** Azure Functions (Custom Handler on Linux Container)

## Development Workflow

### Useful Commands

- `make run`: Starts the server locally on port 8080.
- `make build`: Compiles the project for development.
- `make test`: Runs unit tests in `src/main.rs`.
- `make clippy`: Runs linting.
- `make fmt`: Formats the code.
- `make start`/`stop`/`status`: Manage background server process.
- `make deploy`: Deploys to Azure Function App.
- `make functionapp-status`: Check Function App status and get the endpoint.
- `make functionapp-logs`: Tail logs for the Function App.
- `make functionapp-destroy`: Delete the Function App and Plan.

### Implementation Details
- **Entry Point:** `src/main.rs` defines the `HelloWorld` struct which implements `ServerHandler`.
- **Azure Functions Custom Handler:** The server listens on `FUNCTIONS_CUSTOMHANDLER_PORT` (proxied by Azure Functions).
- **Streaming HTTP:** The server uses `StreamableHttpService` from `rmcp` to handle long-lived HTTP connections for MCP sessions.
- **Session Management:** Configured with a 1-hour session timeout (`LocalSessionManager`) and 15-second SSE keep-alive.
- **Health Check:** A `/health` endpoint is provided for Azure health probes.
- **Environment Variables:** `FUNCTIONS_CUSTOMHANDLER_PORT` (or `PORT`) determines the listening port. `ALLOWED_HOSTS` configures DNS rebinding protection (defaults to `*`).
- **Graceful Shutdown:** Implemented using `tokio::signal`.

## Implemented Tools

- **`greeting`**: Echoes back a provided message.
  - Parameters: `message` (string).
  - Returns: A greeting string.

## Documentation References

- [rmcp Documentation](https://docs.rs/rmcp/latest/rmcp/)
- [Axum Documentation](https://docs.rs/axum/latest/axum/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Azure Functions Custom Handlers](https://learn.microsoft.com/en-us/azure/azure-functions/functions-custom-handlers)

## Tips for Gemini

- **Adding Tools:** Use the `#[tool]` attribute in the `HelloWorld` impl block. Ensure the `tool_router` is correctly initialized in `new()`.
- **Tool Parameters:** Ensure all parameter structs implement `serde::Deserialize` and `schemars::JsonSchema`.
- **Local Sessions:** The `LocalSessionManager` handles MCP session state locally.
- **Tracing:** Use `tracing` for logging. The subscriber is initialized in `main`.
- **Routing:** All requests to `/api/mcp/{*remainder}` are forwarded to the Rust server.
