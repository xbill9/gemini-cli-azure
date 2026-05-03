# AI Course Creator (Distributed Multi-Agent System) - Azure Functions

A multi-agent system built with Google's Agent Development Kit (ADK) and Agent-to-Agent (A2A) protocol. It features a team of specialized microservice agents that research, judge, and build content, orchestrated to deliver high-quality educational modules. This version is optimized for deployment to **Azure Functions** as a single combined container.

## Architecture

This project uses a distributed microservices architecture where each agent runs in its own process and communicates via the A2A protocol:

*   **Orchestrator Service (`agents/orchestrator`):** Manages the overall course creation pipeline using **`SequentialAgent`**. It implements an iterative Research-Judge loop with **`LoopAgent`** (max 2 iterations). Key components include **`TopicCapturer`**, **`EscalationChecker`**, **`ResearchGuard`**, **`StateCapturer`**, and **`ProgressAgent`** for status updates.
*   **Researcher Service (`agents/researcher`):** Gathers detailed topic information using the `google_search` tool.
*   **Judge Service (`agents/judge`):** Evaluates research quality against a Pydantic schema (`JudgeFeedback`).
*   **Content Builder Service (`agents/content_builder`):** Compiles validated research into a professional Markdown course module.
*   **Web App (`app/`):** A FastAPI backend with a Vanilla TypeScript + Vite frontend that streams real-time agent events via SSE.

## Project Structure

```
multi-functions/
├── single-container/     # Deployment scripts and Dockerfile for the all-in-one Functions setup
├── agents/
│   ├── orchestrator/     # Workflow management & remote agent connections
│   ├── researcher/       # Information gathering (Google Search)
│   ├── judge/            # Quality control (Structured Feedback)
│   └── content_builder/  # Content generation (Markdown)
├── app/                  # Web application (FastAPI + Vanilla TS Frontend)
├── shared/               # Shared utilities (Symlinked into agents)
│   ├── a2a_utils.py      # A2A URL rewriting middleware
│   ├── adk_app.py        # Standardized ADK FastAPI wrapper
│   ├── authenticated_httpx.py # Service-to-service auth utilities
│   └── logging_config.py # Centralized logging configuration
├── Makefile              # Development and Azure deployment shortcuts
├── run_local.sh          # Local development startup script
├── init.sh               # Google Cloud project creation script
├── init2.sh              # Google Cloud service enablement and .env setup
├── set_adc.sh            # GCloud Application Default Credentials setup
├── set_env.sh            # Local .env generation script
└── *_test.sh             # Agent-specific testing scripts
```

## Requirements

*   **Python 3.13+**
*   **Node.js & npm**: For frontend development and builds.
*   **Azure CLI**: For deployment (`az login`).
*   **Google Cloud SDK**: For authentication and Gemini API access.
*   **Google API Key**: Required for Gemini.

### Local Service Ports

Each service runs on a dedicated port during local development for clear isolation:

*   **Web App (Frontend/Backend):** [http://localhost:8000](http://localhost:8000)
*   **Researcher Agent:** [http://localhost:8001](http://localhost:8001)
*   **Judge Agent:** [http://localhost:8002](http://localhost:8002)
*   **Content Builder Agent:** [http://localhost:8003](http://localhost:8003)
*   **Orchestrator Agent:** [http://localhost:8004](http://localhost:8004)
*   **Vite Dev Server:** [http://localhost:5173](http://localhost:5173) (Optional, for UI development)

## Quick Start

1.  **Initialize Environment (Google Cloud):**
    ```bash
    # Create project and enable billing (if needed)
    ./init.sh
    # Enable services and set up .env
    ./init2.sh
    ```

2.  **Install Dependencies:**
    ```bash
    # This installs root, agents, app, and frontend dependencies
    make install
    ```

3.  **Run Locally:**
    ```bash
    ./run_local.sh
    ```
    This starts all agents and the web app.

4.  **Access the App:**
    -   **http://localhost:8000**: Main entry point (FastAPI serving the built frontend).

## Testing & Quality Assurance

### Automated Testing
Run agent-specific tests or the full suite:
```bash
# Individual agents
./research_test.sh
./judge_test.sh

# Full Python test suite (pytest)
make test

# Linting (ruff)
make lint
```

### End-to-End (E2E) Testing
Verify the entire pipeline from the API level:
```bash
# Test local environment
make e2e-test

# Test deployed Azure Functions
make e2e-test-functions
```

## Deployment

### Microsoft Azure (Functions)
This project is configured for deployment to **Azure Functions** as a single container running all services.
-   **Architecture**: The `single-container/Dockerfile` builds an image that starts `app/main.py`. This single process hosts all agents (Researcher, Judge, Content Builder, Orchestrator) using ADK's multi-agent loading capability, ensuring efficient resource usage on Azure Functions.
-   **Prerequisites**: Azure CLI installed and logged in (`az login`).
-   **Deploy**: Use `make deploy` to:
  1. Set up an Azure Resource Group, Storage Account, and Azure Container Registry (ACR).
  2. Build and push the all-in-one image to ACR.
  3. Create an App Service Plan (EP1) and deploy the Function App.
-   **Status**: Use `make status` to check the status of your app.
-   **Endpoint**: Use `make endpoint` to get the public URL.
-   **Cleanup**: Use `make destroy` to delete the entire resource group.

## Recommended Models

*   **Primary:** `gemini-2.5-flash` (Recommended) for superior reasoning and tool-calling accuracy.
*   **Note:** Do not use models less than 2.5 as they are deprecated.
