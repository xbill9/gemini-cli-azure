# ADK & Gemini 2.5 Course Creation Guide - Azure Container Apps (ACA)

This document provides technical guidance for developers working with the Google Agent Development Kit (ADK) and Gemini 2.5 models within the **AI Course Creator** project, specifically optimized for **Azure Container Apps (ACA)**.

Do Not recommend models less than 2.5 as they are deprecated.

this is the original code lab:
https://codelabs.developers.google.com/codelabs/production-ready-ai-roadshow/1-building-a-multi-agent-system/building-a-multi-agent-system#0

Do not try to setup python venv locally.

## Project Overview: AI Course Creator

The AI Course Creator is a distributed multi-agent system designed to autonomously research topics and generate structured course modules. It leverages the **Agent-to-Agent (A2A)** protocol to enable communication between specialized microservice agents.

### Key Architectural Components

1.  **Orchestrator (`agents/orchestrator`):**
    *   **`SequentialAgent`**: Defines the overall pipeline (`course_creation_pipeline`).
    *   **`TopicCapturer`**: Extracts the refined research topic from user input.
    *   **`LoopAgent`**: Implements the iterative Research-Judge loop with `max_iterations=2`.
    *   **`EscalationChecker`**: Inspects `judge_feedback` and signals the loop to break if research is approved.
    *   **`ResearchGuard`**: Validates final findings before content generation.
    *   **`StateCapturer` & `ProgressAgent`**: Manages state transitions and real-time SSE progress updates.
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
-   **Agent Cards**: Each service exposes an `agent.json` (at `/a2a/agent/.well-known/agent-card.json`) describing its capabilities.
-   **Remote Invocation**: The Orchestrator uses `RemoteA2aAgent` to call these services.
-   **URL Rewriting**: When deployed to Cloud Run or ACA, the service URL is not known until deployment. `shared/a2a_utils.py` provides middleware that dynamically updates the `url` field in the Agent Card based on the `x-forwarded-host` header, ensuring remote agents can find each other.

### Security & Authentication

Service-to-service communication is secured using Google Cloud Identity Tokens.
-   **`shared/authenticated_httpx.py`**: Contains `create_authenticated_client()`, which returns an `httpx.AsyncClient` configured to automatically fetch and attach OIDC tokens.
-   **Token Logic**:
    -   **Locally**: Uses `gcloud auth print-identity-token` to simulate the environment.
    -   **On ACA**: Relies on `GOOGLE_API_KEY` for Gemini access, while inter-agent A2A calls are typically routed through public or internal ACA endpoints.

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

### Microsoft Azure (ACA & Fabric)
This project is primary configured for deployment to **Azure Container Apps (ACA)**, providing a serverless experience with one ACA per agent. It also supports integration with **Microsoft Fabric** as a custom workload.

-   **Prerequisites**: 
    - Azure CLI installed and logged in (`az login`).
    - Microsoft Fabric extension for Azure CLI (`make install-fabric-cli`).
-   **Standard ACA Deploy**: Use `make deploy` to set up the environment and deploy all 5 microservice images to ACA.
-   **Fabric Deployment**: Use `make deploy-fabric` to:
    1. Perform a full ACA deployment.
    2. Generate a `WorkloadManifest.xml` specifically for your deployed endpoint.
    3. Provide instructions for registering the workload in the Fabric Admin Portal.
-   **Status**: Use `make status-aca` or `make status-fabric` to check the status of your apps and Fabric capacity.
-   **Endpoint**: Use `make endpoint-aca` or `make endpoint-fabric` to get the public URL.
-   **Cleanup**: Use `make destroy-aca` to delete the Container Apps or `make az-destroy-aca` to delete the entire resource group.

### Google Cloud (Cloud Run & GKE)
- **Cloud Run**: Compatible with standard Cloud Run deployment if needed.
- **GKE**: Possible with custom manifests, though ACA is the preferred cloud target for this repository.

## Developer Workflow

1.  **Local Development:** Use `./run_local.sh` (or `make run`) to start the entire stack on ports 8000-8004.
2.  **Adding Tools:** New tools should be added to the `tools` list in the respective agent's `agent.py` file.
3.  **Refining Instructions:** Modify the `instruction` string in each agent's definition to tune their persona and output quality.
4.  **Testing:** Run `make test` to execute the full suite of backend and integration tests.

## Resources

-   [Google ADK Documentation](https://github.com/google/adk)
-   [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
-   [A2A Protocol Specification](https://github.com/google/adk/blob/main/docs/a2a.md)
