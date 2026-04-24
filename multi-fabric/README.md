# AI Course Creator (Distributed Multi-Agent System) - Azure Container Apps

A multi-agent system built with Google's Agent Development Kit (ADK) and Agent-to-Agent (A2A) protocol. It features a team of specialized microservice agents that research, judge, and build content, orchestrated to deliver high-quality educational modules. This version is optimized for deployment to **Azure Container Apps (ACA)** while maintaining compatibility with local development and Google Cloud services.

## Architecture

This project uses a distributed microservices architecture where each agent runs in its own container and communicates via the A2A protocol:

*   **Orchestrator Service (`agents/orchestrator`):** Manages the overall course creation pipeline using **`SequentialAgent`**. It implements an iterative Research-Judge loop with **`LoopAgent`** (max 2 iterations). Key components include **`TopicCapturer`**, **`EscalationChecker`**, **`ResearchGuard`**, **`StateCapturer`**, and **`ProgressAgent`** for status updates.
*   **Researcher Service (`agents/researcher`):** Gathers detailed topic information using the `google_search` tool.
*   **Judge Service (`agents/judge`):** Evaluates research quality against a Pydantic schema (`JudgeFeedback`).
*   **Content Builder Service (`agents/content_builder`):** Compiles validated research into a professional Markdown course module.
*   **Web App (`app/`):** A FastAPI backend with a Vanilla TypeScript + Vite frontend that streams real-time agent events via SSE.

## Project Structure

```
multi-aca/
├── aca/                  # Azure Container Apps deployment scripts
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
*   **Azure CLI**: For ACA deployment (`az login`).
*   **Google Cloud SDK**: For authentication and Gemini API access.
*   **Google API Key**: Required for Gemini (unless using Vertex AI).

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
    This starts all agents and the web app. The Researcher, Judge, and Content Builder run on ports 8001-8003, the Orchestrator on 8004, and the Web App on 8000.

4.  **Access the App:**
    -   **http://localhost:8000**: Main entry point (FastAPI serving the built frontend).
    -   **http://localhost:5173**: Vite dev server (supports hot-reloading for UI development).

## Testing

Run agent-specific tests to verify individual components:
```bash
./research_test.sh
./judge_test.sh
```
Or run the full suite:
```bash
make test
```

## Deployment

### Microsoft Azure (ACA & Fabric)
The system is configured for a serverless experience on Azure, with each agent as an independent Container App. It also supports Microsoft Fabric integration.

1.  **Login to Azure:**
    ```bash
    az login
    ```

2.  **Install Fabric CLI Extensions:**
    ```bash
    make install-fabric-cli
    ```

3.  **Deploy all services:**
    ```bash
    # Standard ACA deployment
    make deploy
    
    # OR Deploy and prepare for Microsoft Fabric
    make deploy-fabric
    ```
    The `deploy-fabric` script handles Resource Group creation, ACR setup, image building, ACA deployment, and generates a `WorkloadManifest.xml`.

4.  **Check Status:**
    ```bash
    make status-aca
    # For Fabric capacity status
    make status-fabric
    ```

5.  **Get Public Endpoint:**
    ```bash
    make endpoint-aca
    ```

### Google Cloud Run
While optimized for ACA, the microservices remain compatible with Cloud Run.

## Recommended Models

*   **Primary:** `gemini-2.5-flash` (Recommended) for superior reasoning and tool-calling accuracy.
*   **Note:** Do not use models less than 2.5 as they are deprecated.
