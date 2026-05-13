# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the project and assist in development.

## Project Overview

This is a **Rust-based Model Context Protocol (MCP) server** using the `rmcp` SDK. It exposes tools over a streaming HTTP transport (SSE) using the `axum` framework, designed for integration with MCP clients like Claude Desktop or Gemini clients. It is specifically optimized for deployment on **Azure Container Apps (ACA)**.

## Key Technologies

*   **Language:** Rust (Edition 2024)
*   **SDK:** `rmcp` (Model Context Protocol SDK for Rust)
    *   Features used: `macros`, `server`, `auth`, `transport-streamable-http-server`.
*   **Web Framework:** `axum` (for HTTP transport and SSE)
*   **Runtime:** `tokio` (asynchronous runtime)
*   **Logging:** `tracing` and `tracing-subscriber`
*   **Serialization:** `serde` and `serde_json`
*   **Dependency Management:** `cargo`
*   **Deployment:** Azure Container Apps (ACA)

## Implementation Details

### MCP Server (`rmcp`)
- The server implements `ServerHandler` for the `HelloWorld` struct.
- Tools are defined using the `#[tool_router]` and `#[tool]` macros.
- The `greeting` tool uses the `Parameters<T>` wrapper for typed request handling.
- Session management is handled by `LocalSessionManager` with a 1-hour timeout (`SessionConfig`).
- The `StreamableHttpService` handles the SSE transport.

### HTTP Layer (`axum`)
- The `/mcp` path is nested to the `StreamableHttpService`.
- A `/health` endpoint is provided for ACA health probes.
- Graceful shutdown is implemented for SIGINT and SIGTERM.

## Development Patterns

### Adding a New Tool
1. Define a request struct and derive `serde::Deserialize` and `schemars::JsonSchema`.
2. Add a new `async fn` to the `#[tool_router]` implementation of `HelloWorld`.
3. Annotate the function with `#[tool(description = "...")]`.
4. Use `Parameters<YourStruct>` as the first argument to access tool parameters.

Example:
```rust
#[derive(serde::Deserialize, schemars::JsonSchema)]
struct MyToolRequest {
    name: String,
}

#[tool_router]
impl HelloWorld {
    #[tool(description = "My new tool")]
    async fn my_tool(&self, Parameters(req): Parameters<MyToolRequest>) -> String {
        format!("Hello, {}!", req.name)
    }
}
```

## Project Structure

* `src/main.rs`: The entry point. Defines the `HelloWorld` server handler, tool router, and sets up the `axum` server with `rmcp`'s `StreamableHttpService`. Includes a `/health` endpoint and graceful shutdown.
* `Cargo.toml`: Rust package configuration and dependencies.
* `Makefile`: Development and deployment shortcuts, including Azure CLI integration.
* `Dockerfile`: Multi-stage build configuration using `rust:1.95-bookworm` and a distroless base.

## Development Setup

1.  **Ensure Rust is installed:**
    ```bash
    rustc --version
    ```

2.  **Build the project:**
    ```bash
    make build
    ```

3.  **Run tests:**
    ```bash
    make test
    ```

## Running the Server

The server runs on `http://0.0.0.0:8080` by default (configurable via `PORT` environment variable).

```bash
make run
```

*Note: This server uses SSE (Server-Sent Events) for the MCP transport. The MCP endpoint is at `/mcp`.*

## Configuration

The application supports the following environment variables:

- `PORT`: The port to listen on (default: `8080`).
- `ALLOWED_HOSTS`: Comma-separated list of allowed hostnames (e.g., `example.com,localhost`). Set to `*` to allow all (default for ACA).
- `RUST_LOG`: Logging levels (default: `info,mcp_aca_rust_azure=debug,rmcp=debug`).

## Code Quality
...
*   **Linting:** `make lint` (runs `cargo clippy`)
*   **Formatting:** `make fmt` (runs `cargo fmt`)
*   **Checking:** `make check` (runs `cargo check`)

## Deployment

The project is configured for deployment to **Azure Container Apps (ACA)**.

### Deployment Prerequisites
- Azure CLI installed and logged in (`az login`).
- Docker installed locally (for image builds).

### Deployment Steps
1.  **Deploy to Azure:** `make deploy`
    - This command handles ACR creation, image build, push to ACR, ACA Environment setup, and ACA deployment.
2.  **View Logs:** `make logs` (tails ACA logs)
3.  **Check Status:** `make status` (checks both local and ACA status)
4.  **Get Endpoint:** `make endpoint`
5.  **Destroy Resources:** `make destroy` (Deletes the resource group and all associated resources)

## Rust MCP Developer Resources

*   **`rmcp` Crate:** [https://crates.io/crates/rmcp](https://crates.io/crates/rmcp)
*   **Axum Documentation:** [https://docs.rs/axum/latest/axum/](https://docs.rs/axum/latest/axum/)
*   **Tokio Documentation:** [https://tokio.rs/](https://tokio.rs/)
