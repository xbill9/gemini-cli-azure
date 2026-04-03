# ADK Comic Pipeline (Azure AKS Edition)

This repository contains an agentic pipeline for generating comic books, built using the **Google Agent Development Kit (ADK)** and **Gemini 2.5 Flash**. It is specifically configured for high-performance deployment to **Azure Kubernetes Service (AKS)**.

It is based on the solution to the codelab: [Create a low-code agent with ADK visual builder](https://codelabs.developers.google.com/codelabs/create-low-code-agent-with-ADK-visual-builder)

## Features

- **Automated Scripting**: Narrative and Character Architect that generates creative comic scripts and character manifests from high-level prompts.
- **Intelligent Panelization**: Cinematographer and Storyboarder that breaks down scripts into exactly 8 storyboarded panels.
- **AI Image Synthesis**: Technical Artist that generates 16:9 images for each panel using **Imagen 4.0** and **Gemini 2.5 Flash** for multimodal refinement.
- **HTML Assembly**: Frontend Developer that compiles final artwork and script into a responsive HTML comic book.
- **Comic Inspection**: Dedicated **Agent4** for summarizing and exporting generated comics as UI artifacts for viewing within the ADK Builder.
- **Agent Coordination**: **Agent2** demonstrates a sophisticated sub-agent hierarchy with specialized Prompt Engineering and Image Generation stages.
- **Kubernetes Native**: Optimized Docker environment (**Python 3.13 + uv**) deployed to **AKS** with automated scaling and service discovery.

## Project Structure

- `Agent1/`: **Real-time Search**. A basic agent featuring the `google_search` tool.
- `Agent2/`: **Multistage Image Generation**. Uses a `SequentialAgent` pipeline with a specialized **Prompt Engineer** and **Technical Artist**.
- `Agent3/`: **The Production Pipeline**. The primary 4-stage sequential workflow managed by a **Studio Director**.
- `Agent4/`: **The Comic Inspector**. Inspects, summarizes, and **exports** generated comics as artifacts for seamless viewing in the ADK UI.
- `images/`: Directory where intermediate panel images are stored.
- `output/`: Final output directory containing `comic.html` and assets.

## Scripts & Utilities

- `agent_builder`: Launches the ADK Builder UI (accessible via browser).
- `myadk`: A convenience wrapper for the `adk` CLI tool.
- `comic.sh`: Starts a local web server (port 8080) to view the generated comic.
- `deploy-aks.sh`: Main deployment script for Azure Kubernetes Service.
- `init.sh`: Comprehensive setup script to configure the project and install dependencies.
- `set_env.sh` / `set_adc.sh`: Helpers to set environment variables and refresh credentials.

## Makefile Commands

- `make run`: Runs the ADK Web UI locally (port 8080).
- `make deploy`: Deploys the entire stack to **Azure Kubernetes Service (AKS)**.
- `make status`: Checks the status of AKS pods, deployments, and services.
- `make logs`: Tails the logs from the running AKS pods.
- `make endpoint`: Retrieves the public LoadBalancer IP for the AKS deployment.
- `make clean`: Removes log files, generated images, and temporary cache directories.

## How it Works

### Agent3: Production Workflow
The `Studio Director` agent (`root_agent.yaml`) delegates to a `SequentialAgent` (`comic_pipeline_agent.yaml`), coordinating four specialized stages:
1. **Scripting Agent**: Creates the narrative arc and character descriptions.
2. **Panelization Agent**: Defines exactly 8 visual frames.
3. **Image Synthesis Agent**: Calls the `generate_image` tool using Imagen 4.0 for new assets and Gemini 2.5 Flash for edits.
4. **Assembly Agent**: Generates the final responsive HTML layout.

### Agent4: Review & Export
The `Comic Inspector` provides tools to:
1. **List Assets**: Quickly see what images and comics have been generated.
2. **Summarize**: Get a text-based overview of the generated story.
3. **Export Artifacts**: Converts the generated comic into self-contained ADK Artifacts, allowing for high-fidelity viewing directly within the ADK Visual Builder / Studio UI without needing a separate web server.

## Known Bugs & Workarounds

*   **Environment Variables**: After editing `.env`, run `source .env` or `./set_env.sh`.
*   **YAML Nesting**: ADK CLI may nest YAML configurations incorrectly. They must be moved to the agent root.
*   **Issue Tracking**: See [google/adk-python Issue #4134](https://github.com/google/adk-python/issues/4134).

## Getting Started

1.  **Initialize Project**: Run `./init.sh` to set up your environment.
2.  **Deploy to AKS**:
    ```bash
    make deploy
    ```
3.  **Access the UI**:
    Retrieve your endpoint: `make endpoint`
    Open the IP in your browser at port 80.
4.  **Run Pipeline**:
    ```bash
    adk run Agent3 --input "Create me a comic about a space explorer on a neon planet."
    ```
