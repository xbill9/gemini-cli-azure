# AI Course Creator (Distributed Multi-Agent System) - Fabric Stacked Edition

A multi-agent system built with Google's Agent Development Kit (ADK) and Agent-to-Agent (A2A) protocol. It features a team of specialized microservice agents that research, judge, and build content, orchestrated to deliver high-quality educational modules. 

This version is optimized for **stacked deployment** to **Microsoft Fabric** using **Azure Container Apps (ACA)** for hosting the microservices.

## Architecture

This project uses a distributed microservices architecture where each agent runs in its own container and communicates via the A2A protocol:

*   **Orchestrator Service (`agents/orchestrator`):** Manages the overall course creation pipeline using **`SequentialAgent`**. It implements an iterative Research-Judge loop with **`LoopAgent`** (max 2 iterations). Key components include **`TopicCapturer`**, **`EscalationChecker`**, **`ResearchGuard`**, **`StateCapturer`**, and **`ProgressAgent`** for status updates.
*   **Researcher Service (`agents/researcher`):** Gathers detailed topic information using the `google_search` tool.
*   **Judge Service (`agents/judge`):** Evaluates research quality against a Pydantic schema (`JudgeFeedback`).
*   **Content Builder Service (`agents/content_builder`):** Compiles validated research into a professional Markdown course module.
*   **Web App (`app/`):** A FastAPI backend with a Vanilla TypeScript + Vite frontend that streams real-time agent events via SSE.

## Project Structure

```
multi-fabric/
├── fabric/               # Microsoft Fabric & Azure Container Apps deployment
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
├── Makefile              # Development and Azure Fabric deployment shortcuts
├── run_local.sh          # Local development startup script
└── *_test.sh             # Agent-specific testing scripts
```

## Requirements

*   **Python 3.13+**
*   **Node.js & npm**: For frontend development and builds.
*   **Azure CLI**: For ACA deployment (`az login`).
*   **Microsoft Fabric extension**: For Fabric integration (`make install-fabric-cli`).
*   **Google API Key**: Required for Gemini (placed in `~/gemini.key`).

## Quick Start

1.  **Install Dependencies:**
    ```bash
    # This installs root, agents, app, and frontend dependencies
    make install
    ```

2.  **Run Locally:**
    ```bash
    make start
    ```
    This starts all agents and the web app. The Researcher, Judge, and Content Builder run on ports 8001-8003, the Orchestrator on 8004, and the Web App on 8000.

3.  **Access the App:**
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

### Microsoft Fabric (Stacked on ACA)
The system is configured for a stacked microservice deployment on Azure Container Apps, integrated as a Microsoft Fabric workload.

1.  **Login to Azure:**
    ```bash
    az login
    ```

2.  **Install Fabric CLI Extensions:**
    ```bash
    make install-fabric-cli
    ```

3.  **Deploy the Stack:**
    ```bash
    make deploy
    ```
    This script handles Resource Group creation, ACR setup, image building, ACA deployment for all 5 services, and generates a `WorkloadManifest.xml` for Fabric.

4.  **Check Status:**
    ```bash
    make status
    ```

5.  **Get Public Endpoint:**
    ```bash
    make endpoint
    ```

## Recommended Models

*   **Primary:** `gemini-2.5-flash` (Recommended) for superior reasoning and tool-calling accuracy.
*   **Note:** Do not use models less than 2.5 as they are deprecated.
