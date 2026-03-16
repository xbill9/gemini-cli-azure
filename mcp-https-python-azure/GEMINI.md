# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the project and assist in development.

## Project Overview

This is a **Python-based Model Context Protocol (MCP) server** using the `FastMCP` class from the `mcp` SDK. It is designed to expose tools (like `greet`) over HTTP for integration with MCP clients (such as Claude Desktop or Gemini clients).

## Key Technologies

*   **Language:** Python 3
*   **SDK:** `mcp` (Model Context Protocol SDK)
*   **Library:** `FastMCP` (for simplified server creation)
*   **Logging:** `python-json-logger`
*   **Dependency Management:** `pip` / `requirements.txt`

## Project Structure

* `main.py`: The entry point of the application. Initializes the `FastMCP` server ("hello-world-server") and defines tools.
* `requirements.txt`: Python dependencies.
* `Makefile`: Development shortcuts (test, lint, clean, deploy).

## Development Setup

1.  **Create and activate a virtual environment (optional but recommended):**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```

2.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

## Running the Server

The server is configured to run using the `HTTP` transport on `http://0.0.0.0:8080`.

```bash
python main.py
```

*Note: This is an MCP server running over HTTP and should be started before an MCP client attempts to connect to it.*

## Deployment

The project includes a `Dockerfile` for containerization and a `cloudbuild.yaml` for automated deployment to Google Cloud Run.

*   **Build Docker image:** `make docker-build`
*   **Deploy to Cloud Run:** `make deploy`

## Python MCP Developer Resources

*   **MCP Python SDK (GitHub):** [https://github.com/mcp-protocol/mcp-python-sdk](https://github.com/mcp-protocol/mcp-python-sdk)
*   **FastMCP Documentation:** [https://gofastmcp.com/](https://gofastmcp.com/)
*   **`mcp` package on PyPI:** [https://pypi.org/project/mcp/](https://pypi.org/project/mcp/)

