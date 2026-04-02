# ADK Comic Pipeline (Fabric Edition)

This repository contains an agentic pipeline for generating comic books, built using the **Google Agent Development Kit (ADK)** and **Vertex AI**, optimized for **Microsoft Fabric** as an MCP server.

It is deployed as an **Azure Container Apps (ACA)** backend, providing a seamless integration for Fabric workloads.

## Features

- **Microsoft Fabric Integration**: Exposes a Model Context Protocol (MCP) server for Fabric to interact with ADK agents.
- **Automated Scripting**: Generates creative comic scripts and character manifests from high-level prompts.
- **Intelligent Panelization**: Breaks down scripts into exactly 8 storyboarded panels.
- **AI Image Synthesis**: Generates 16:9 images for each panel using the **Google GenAI SDK** (Imagen).
- **HTML Assembly**: Compiles the final artwork and script into a responsive HTML comic book.
- **Comic Inspection**: Dedicated agent for summarizing and exporting generated comics as UI artifacts.
- **Azure Deployment**: Optimized Docker environment (**Python 3.13 + uv**) for **Azure Container Apps**.

## Project Structure

- `main.py`: The entry point for the **FastMCP** server (HTTP transport).
- `Agent1/`, `Agent2/`, `Agent3/`, `Agent4/`: ADK Agent configurations.
- `Agent3/`: The primary comic pipeline implementation (Sequential Pipeline).
- `Agent4/`: Comic Reader agent for inspecting and exporting generated comics.
- `Agent3/tools/`: Shared tools for image generation and file writing.
- `Agent4/tools/`: Dedicated tools for comic inspection.


## Scripts & Utilities

- `agent_builder`: Launches the ADK Builder UI (accessible via browser) for visual agent design.
- `myadk`: A convenience wrapper for the `adk` CLI tool.
- `comic.sh`: Starts a local web server (port 8080) to view the generated comic.
- `deploy-azure.sh`: Wrapper script to deploy the agent container to Azure Container Apps.
- `init.sh`: Comprehensive setup script to configure the environment and install dependencies.
- `set_env.sh` / `set_adc.sh`: Helpers to set environment variables and refresh Azure/Google credentials.

## Makefile Commands

- `make deploy`: Primary command for **Azure Container Apps** deployment (Build, Push to ACR, and Deploy).
- `make az-status`: Checks the current state and URL of the Azure Container App.
- `make endpoint`: Retrieves the public FQDN for Fabric integration.
- `make clean`: Removes log files and temporary cache directories.

## How it Works (Production Pipeline)

The system uses a `Studio Director` agent (`Agent3/root_agent.yaml`) that delegates to a `SequentialAgent` (`Agent3/comic_pipeline_agent.yaml`), coordinating four specialized stages:
1. **Scripting Agent**: Narrative and Character Architect.
2. **Panelization Agent**: Cinematographer and Storyboarder.
3. **Image Synthesis Agent**: Technical Artist and Asset Generator.
4. **Assembly Agent**: Frontend Developer for final packaging.

The final output is exposed via the **FastMCP** server in `main.py`, allowing Microsoft Fabric to trigger comic creation and retrieve results.

## Deployment to Microsoft Azure

To deploy the project as a container to Azure Container Apps:
```bash
make deploy
```
After deployment, use `make endpoint` to get the FQDN for your Fabric `WorkloadManifest.xml`.

## Getting Started (Local)

1.  **Initialize Project**: Run `./init.sh` to install dependencies and configure credentials.
2.  **Verify Environment**: Ensure `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` are set in the `.env` file.
3.  **Run Pipeline**: Execute the comic creation pipeline for Agent3:
    ```bash
    adk run Agent3 --input "Create me a comic about a space explorer on a neon planet."
    ```
4.  **View Results**: Run `./comic.sh` and open `http://localhost:8080`.
