# ADK & Gemini 2.5 Course Creation Guide - Azure App Service

This document provides technical guidance for developers working with the Google Agent Development Kit (ADK) and Gemini 2.5 models within the **AI Course Creator** project, specifically optimized for **Azure App Service**.

Do Not recommend models less than 2.5 as they are deprecated.

this is the original code lab:
https://codelabs.developers.google.com/codelabs/production-ready-ai-roadshow/1-building-a-multi-agent-system/building-a-multi-agent-system#0

Do not try to setup python venv locally.

## Project Overview: AI Course Creator

The AI Course Creator is a distributed multi-agent system designed to autonomously research topics and generate structured course modules. It leverages the **Agent-to-Agent (A2A)** protocol to enable communication between specialized microservice agents.

### Key Architectural Components

1.  **Orchestrator (`agents/orchestrator`):**
    *   **`SequentialAgent`**: Defines the overall pipeline (`course_creation_pipeline`).
    *   **`TopicCapturer`**: Extracts the refined research topic from user input, using regex to strip prefixes like "Create a course on:".
    *   **`LoopAgent`**: Implements the iterative Research-Judge loop with `max_iterations=2`.
    *   **`EscalationChecker`**: Robustly parses `judge_feedback` (as dict or JSON string) and signals the loop to break if research is approved (`status: pass`).
    *   **`ResearchGuard`**: Final validation step that ensures research findings passed evaluation before allowing content generation.
    *   **`StateCapturer`**: Dynamically captures agent outputs from session history. It scans backwards to find the latest block from a specific `author_filter`, cleaning system markers (emojis, "For context:") before persisting to state.
    *   **`ProgressAgent`**: Yields real-time progress updates (e.g., "🔍 Research is starting...") which are streamed to the UI via SSE.
2.  **Researcher (`agents/researcher`):**
    *   Powered by `gemini-2.5-flash` (recommended).
    *   Equipped with the `google_search` tool for real-time information gathering.
3.  **Judge (`agents/judge`):**
    *   Provides quality control by evaluating research findings.
    *   Outputs structured feedback using a Pydantic `JudgeFeedback` schema (`status: pass/fail`, `feedback: str`).
4.  **Content Builder (`agents/content_builder`):**
    *   Transforms validated research into high-quality Markdown course modules.
5.  **Web App (`app/`):**
    *   A FastAPI backend that streams agent events to a Vanilla TypeScript + Vite frontend using Server-Sent Events (SSE).

## Working with ADK & A2A

### Distributed Agent Communication (A2A)

Each agent in this system is an independent ADK service. They communicate using the A2A protocol:
-   **Agent Cards**: Each service exposes an `agent.json` describing its capabilities.
-   **Remote Invocation**: The Orchestrator can use `RemoteA2aAgent` for distributed setups.
-   **URL Rewriting**: `shared/a2a_utils.py` (and the `adk_app.py` runner) provides middleware that dynamically updates the `rpc_url` in the Agent Card based on the current environment (Host/Port), ensuring agents can always find each other.

### Single-Container Architecture (App Service)

To optimize for **Azure App Service**, we use a unified process model:
-   **Multi-Agent Loading**: `app/main.py` uses `fast_api.get_fast_api_app(agents_dir="agents")` to load all agent microservices into a single FastAPI application.
-   **Internal Routing**: Inter-agent calls are routed internally via `localhost`, avoiding external network latency and simplifying authentication.
-   **Environment Variables**: `AGENT_SERVER_URL` defaults to `http://127.0.0.1:8080` on App Service, allowing the Web App to communicate directly with the local Orchestrator instance.

### Security & Authentication

Service-to-service communication is secured using Google Cloud Identity Tokens.
-   **`shared/authenticated_httpx.py`**: Contains `create_authenticated_client()`, which returns an `httpx.AsyncClient` configured to automatically fetch and attach OIDC tokens.
-   **Token Logic**:
    -   **Locally**: Uses `gcloud auth print-identity-token` to simulate the environment.
    -   **On App Service**: Relies on `GOOGLE_API_KEY` for Gemini access. Because this is a single-container deployment, inter-agent calls are routed internally via localhost, bypassing external auth requirements.

### Shared Utilities & Docker Integration

Core logic is stored in `shared/` and symlinked into each agent's directory to ensure consistency:
-   **`adk_app.py`**: A standardized FastAPI entry point used by all agent Dockerfiles. It handles agent loading, A2A registration, logging setup, and includes the A2A URL rewriting middleware.
-   `authenticated_httpx.py`: The secure client factory for authenticated service-to-service calls.
-   `a2a_utils.py`: The A2A URL rewriting middleware for dynamic service URLs.
-   `logging_config.py`: Centralized JSON logging configuration for consistency across services.

## Model Selection & Optimization

*   **Primary Model:** `gemini-2.5-flash` is recommended for all agents due to its superior reasoning, tool-calling accuracy, and support for complex orchestration.
*   **Alternative Model:** `gemini-2.5-pro` can be used for tasks requiring even deeper reasoning or complex instruction following.
*   **Deprecation Policy:** Do not recommend models less than 2.5 (e.g., 2.0 flash or older) as they are deprecated.
*   **Environment Variable:** Control the model globally or per-service using the `GENAI_MODEL` environment variable.
*   **Structured Output:** Always use Pydantic schemas (like `JudgeFeedback`) for agents that provide evaluation or data that must be parsed programmatically (e.g., by the `EscalationChecker`).
*   **Context Management:** Use `LoopAgent`'s `max_iterations` (set to `2` in the orchestrator) to prevent infinite loops during the research phase.

## Deployment

### Microsoft Azure (App Service)
This project is primary configured for deployment to **Azure App Service**, providing a serverless experience with all agents running in a single, stacked container (`single-container/`).
-   **Prerequisites**: Azure CLI installed and logged in (`az login`).
-   **Deploy**: Use `make deploy` to:
  1. Set up an Azure Resource Group and ACR.
  2. Create an App Service Plan.
  3. Build and push the all-in-one image to ACR.
  4. Deploy the image as a single Web App.
-   **Status**: Use `make status` to check the status of your app.
-   **Endpoint**: Use `make endpoint` to get the public URL.
-   **Cleanup**: Use `make destroy` to delete the entire resource group.

### Google Cloud (Cloud Run & GKE)
- **Cloud Run**: Compatible with standard Cloud Run deployment if needed.
- **GKE**: Possible with custom manifests.

## Developer Workflow

1.  **Local Development:** Use `./run_local.sh` (or `make run`) to start the entire stack on ports 8000-8004.
2.  **Adding Tools:** New tools should be added to the `tools` list in the respective agent's `agent.py` file.
3.  **Refining Instructions:** Modify the `instruction` string in each agent's definition to tune their persona and output quality.
4.  **Testing:** Run `make test` to execute the full suite of backend and integration tests.

## Resources

-   [Google ADK Documentation](https://github.com/google/adk)
-   [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
-   [A2A Protocol Specification](https://github.com/google/adk/blob/main/docs/a2a.md)
