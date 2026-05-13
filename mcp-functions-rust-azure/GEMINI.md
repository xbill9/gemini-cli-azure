# Gemini Workspace for `mcp-functions-rust-azure`

You are a Rust Developer working with Microsoft Azure.
Follow Rust best practices and idiomatic patterns (2024 edition).

## Project Overview

`mcp-functions-rust-azure` is a streaming HTTP MCP server written in Rust, designed for deployment on Azure Functions (Custom Handler). It uses the `rmcp` library to provide tools to LLM agents via the Model Context Protocol.

### Key Technologies

*   **Language:** Rust (2024 Edition)
*   **MCP Framework:** [`rmcp`](https://github.com/modelcontextprotocol/rust-sdk) (v1.6.0)
    *   Uses `#[tool_router]`, `#[tool]`, and `#[tool_handler]` macros for ergonomic tool definition.
*   **Web Framework:** [Axum](https://docs.rs/axum/latest/axum/) (v0.8.9)
    *   Handles routing, health checks, and middleware.
*   **Runtime:** [Tokio](https://tokio.rs/) (v1.52.1)
    *   Multi-threaded asynchronous runtime.
*   **Deployment:** Azure Functions (Custom Handler on Linux Container)
    *   Requests are proxied from Azure Functions to the Rust server.

## Development Workflow

### Useful Commands

- `make build`: Compiles the project for development.
- `make run`: Starts the server locally in the foreground.
- `make start`: Builds and starts the server in the background (logs to `server.log`, PID in `server.pid`).
- `make stop`: Stops the background server.
- `make status`: Checks status of both local background process and Azure Function App.
- `make test`: Runs unit tests in `src/main.rs`.
- `make clippy`: Runs linting (must be clean for release).
- `make fmt`: Formats the code.
- `make deploy`: Full automation to build and deploy to Azure.
- `make endpoint`: Prints the deployed MCP endpoint URL.
- `make functionapp-logs`: Tail logs for the Function App in Azure.
- `make destroy`: Teardown all Azure resources.

### Implementation Details

- **Entry Point:** `src/main.rs` contains the `main` function and the `HelloWorld` struct.
- **`HelloWorld` Struct:**
  - Implements `ServerHandler` via `#[tool_handler]`.
  - Defines tools via `#[tool_router]` and `#[tool]`.
- **Azure Functions Custom Handler:**
  - Listens on `FUNCTIONS_CUSTOMHANDLER_PORT` (proxied by Azure).
  - Falls back to `PORT` if the former is not set.
- **Streaming HTTP:**
  - Uses `StreamableHttpService` from `rmcp`.
  - SSE keep-alive is set to 15 seconds.
- **Session Management:**
  - `LocalSessionManager` is used with a 1-hour session timeout.
- **Routing:**
  - `/health`: Top-level health check.
  - `/api/mcp/health`: Nested health check under the MCP route.
  - `/api/mcp/{*remainder}`: Forwarded to the MCP service.
- **DNS Rebinding Protection:**
  - `ALLOWED_HOSTS` env var configures the check.
  - Defaults to `0.0.0.0`, `localhost`, `127.0.0.1`.
  - Set `ALLOWED_HOSTS=*` to disable host validation (useful in some container environments).

## Implemented Tools

- **`greeting`**: Echoes back a provided message.
  - Parameters: `message` (string).
  - Returns: A greeting string.

## Tips for Gemini

- **Adding Tools:**
  1. Define a request struct with `#[derive(serde::Deserialize, schemars::JsonSchema)]`.
  2. Add an `async` method to the `HelloWorld` block with the `#[tool]` attribute.
  3. Ensure parameters use the `Parameters<T>` wrapper.
- **Tracing:** Use `tracing` macros (`info!`, `debug!`, `error!`) for logging. The subscriber is initialized in `main`.
- **Testing:** Add new test cases to the `mod tests` block at the bottom of `src/main.rs`.
- **Azure Configuration:** Environment variables like `ALLOWED_HOSTS` are set during `make deploy` via `az functionapp config appsettings set`.
