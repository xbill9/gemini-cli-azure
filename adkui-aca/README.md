# ADK Comic Pipeline

This repository contains an agentic pipeline for generating comic books, built using the **Google Agent Development Kit (ADK)** and **Vertex AI**. It supports multi-cloud deployment to **Google Cloud** and **Microsoft Azure**.

It is based on the solution to the codelab: [Create a low-code agent with ADK visual builder](https://codelabs.developers.google.com/codelabs/create-low-level-agent-with-ADK-visual-builder)

## Features

- **Automated Scripting**: Generates creative comic scripts and character manifests from high-level prompts.
- **Intelligent Panelization**: Breaks down scripts into exactly 8 storyboarded panels.
- **AI Image Synthesis**: Generates 16:9 images for each panel using **Imagen 4.0** (via Google GenAI SDK).
- **HTML Assembly**: Compiles the final artwork and script into a responsive HTML comic book.
- **Comic Inspection**: Dedicated agent for summarizing and exporting generated comics as UI artifacts.
- **Multi-Cloud Deployment**: Optimized Docker environment (**Python 3.13 + uv**) for deployment to **Google Cloud Run** and **Azure App Service**.
- **Low-Code Interface**: Use the ADK Builder for visual agent development.

## Project Structure

- `Agent1/`: A basic agent featuring a Google Search tool. Uses `root_agent.yaml`.
- `Agent2/`: An agent focused on image generation using sub-agents. Uses `root_agent.yaml` and `sub_agent_*.yaml`.
- `Agent3/`: The primary comic pipeline implementation (Sequential Pipeline).
  - `root_agent.yaml`: The Studio Director agent that manages the pipeline.
  - `comic_pipeline_agent.yaml`: Orchestrates the `SequentialAgent` workflow.
- `Agent4/`: Comic Reader agent for inspecting, summarizing, and exporting generated comics to the ADK UI.
- `images/`: Directory where intermediate panel images are stored.
- `output/`: The final output directory containing `comic.html` and assets.

## Scripts & Utilities

- `agent_builder`: Launches the ADK Builder UI (accessible via browser) for visual agent design.
- `myadk`: A convenience wrapper for the `adk` CLI tool.
- `comic.sh`: Starts a local web server (port 8080) to view the generated comic.
- `deploy-azure.sh`: Deploys the agent container to Azure App Service via ACR.
- `deploy-aci.sh`: Deploys the agent container to Azure Container Instance via ACR.
- `deploycloudrun.py`: Automates deployment to Google Cloud Run, including IAM and Service Account setup.
- `fix_comic.py`: Manual utility to regenerate the `comic.html` with a default story (Momotaro).
- `init.sh`: Comprehensive setup script to configure the GCP project, enable APIs, and install dependencies.
- `set_env.sh` / `set_adc.sh`: Helpers to set environment variables and refresh Application Default Credentials.

## Makefile Commands

- `make clean`: Removes log files, generated images, and temporary cache directories.
- `make deploy`: Primary command for **Azure Container Instance (ACI)** deployment (Default).
- `make deploy-appservice`: Deploys to **Azure App Service**.
- `make status`: Checks the current state and URL of the Azure Container Instance (Default).
- `make logs`: Tails the logs from the Azure Container Instance (Default).
- `make az-status`: Checks the current state and URL of the Azure App Service.
- `make az-logs`: Tails the logs from the Azure App Service.
- `make endpoint`: Retrieves the public URLs for both Azure App Service and ACI deployments.

## How it Works (Agent3 & Agent4)

### Agent3: Production Pipeline
The system uses a `Studio Director` agent (`root_agent.yaml`) that delegates to a `SequentialAgent` (`comic_pipeline_agent.yaml`), coordinating four specialized stages:
1. **Scripting Agent**: Narrative and Character Architect.
2. **Panelization Agent**: Cinematographer and Storyboarder.
3. **Image Synthesis Agent**: Technical Artist and Asset Generator (using Imagen 4.0).
4. **Assembly Agent**: Frontend Developer for final packaging.

### Agent4: Reader & Exporter
This agent provides tools to inspect the `output/` directory, summarize the generated story, and **export the comic as artifacts** (embedded HTML and images) which can be viewed directly within the ADK UI's Artifacts pane.

## Known Bugs & Workarounds

*   **Environment Variables**: After editing `.env`, run `source .env` or `./set_env.sh` to update your shell.
*   **YAML Nesting**: The ADK CLI may nest YAML configurations in subdirectories incorrectly. They must be moved to the root of the respective agent's directory.
*   **Issue Tracking**: See [google/adk-python Issue #4134](https://github.com/google/adk-python/issues/4134).

## Getting Started

1.  **Initialize Project**: Run `./init.sh` to set up your Google Cloud project, enable APIs, and install dependencies.
2.  **Verify Environment**: Ensure `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` are set in the `.env` file.
3.  **Run Pipeline**: Execute the comic creation pipeline for Agent3:
    ```bash
    adk run Agent3 --input "Create me a comic about a space explorer on a neon planet."
    ```
4.  **View Results**: Run `./comic.sh` and open `http://localhost:8080` in your browser, or use **Agent4** to export the comic to the ADK UI.

## Deployment

### Microsoft Azure (Recommended)
To deploy the project as a container to Azure App Service:
```bash
make deploy
```

Alternatively, to deploy as an Azure Container Instance (ACI):
```bash
make deploy-aci
```

Or using the wrapper script:
```bash
./deploy-azure.sh --aci
```

### Google Cloud Run
To deploy an agent (default Agent1) to Google Cloud Run:
```bash
python3 deploycloudrun.py
```
*Note: Edit `deploycloudrun.py` to change the default target agent.*
