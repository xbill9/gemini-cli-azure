# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the ADK (Agent Development Kit) project for building an agentic comic book pipeline.

## Project Overview

This project implements a multi-agent system using the **Google ADK** to automate the creation of comic books. It follows a sequential pipeline where specialized agents handle scripting, panelization, image synthesis, and assembly. It also supports multi-cloud deployment to Google Cloud and Microsoft Azure.

It is based on the solution to the codelab: [Create a low-code agent with ADK visual builder](https://codelabs.developers.google.com/codelabs/create-low-code-agent-with-ADK-visual-builder)

## Key Technologies

*   **Framework:** Google ADK (Agent Development Kit) [Docs](https://google.github.io/adk-docs/)
*   **Language:** Python 3.13
*   **Generative AI:** Google GenAI SDK (`google-genai`), configured for Google AI (API Key) or Vertex AI (ADC).
*   **Cloud Platforms:** Google Cloud (Run, Vertex AI), Microsoft Azure (Container Instance)
*   **Models:**
    *   **LLM Tasks:** `gemini-2.5-flash` (standard) or `gemini-2.5-flash-native-audio-preview-12-2025` (deployed).
    *   **Image Gen:** `imagen-4.0-fast-generate-001`.
*   **Environment:** `.env` for configuration; `uv` used for fast dependency management in Docker.

**Important:** Do not suggest `gemini-2.0` models; they are deprecated.

## Project Structure

*   `Agent1/`: Simple agent with a Google Search tool. Uses `root_agent.yaml`.
*   `Agent2/`: Image generation agent demonstrating sub-agent coordination.
*   `Agent3/`: Primary comic pipeline implementation (Sequential Pipeline).
    *   `root_agent.yaml`: Studio Director.
    *   `comic_pipeline_agent.yaml`: Orchestrator.
    *   `scripting_agent.yaml`, `panelization_agent.yaml`, `image_synthesis_agent.yaml`, `assembly_agent.yaml`: Specialized stage agents.
    *   `tools/`: `image_generation.py` (Google GenAI/Imagen 4.0) and `file_writer.py` (HTML generation).
*   `Agent4/`: Comic Reader agent.
    *   `tools/comic_reader.py`: Tools for listing, summarizing, and exporting comics as ADK artifacts.
*   `images/` & `output/`: Local storage for generated assets and final `comic.html`.

## Tools & Scripts

*   **ADK Development**:
    *   `agent_builder`: Launches the ADK Builder UI.
    *   `myadk`: Wrapper for `adk` CLI.
*   **Deployment**:
    *   `deploy-aci.sh`: Main script for Azure Container Instance (ACI) deployment.
    *   `deploycloudrun.py`: Script for Google Cloud Run deployment.
    *   `Dockerfile`: `python:3.13-slim` image using `uv` for fast package management.
*   **Utility**:
    *   `init.sh`: Project initialization script.
    *   `comic.sh`: Local server for viewing comics.
    *   `fix_comic.py`: HTML regeneration utility.

## Makefile Commands

*   `make deploy` or `make deploy-aci`: Primary command for Azure Container Instance deployment (ACR + ACI).
*   `make status`: Monitor the Azure ACI deployment state.
*   `make logs`: Tail logs from Azure Container Instance.
*   `make endpoint`: Retrieve the public URL for the Azure ACI deployment.
*   `make destroy`: Tear down all Azure resources (ACI, ACR, and Resource Group).
*   `make clean`: Purge logs and generated images.

## Known Bugs & Workarounds

*   **Environment Variables:** After editing `.env`, you must `source .env` or run `./set_env.sh`.
*   **YAML Nesting:** The ADK CLI may nest YAML configurations in subdirectories incorrectly. They must be moved to the root of the respective agent's directory.
*   **Issue Tracker:** Refer to [adk-python Issue #4134](https://github.com/google/adk-python/issues/4134).

## Workflow (Agent3)

1.  **Scripting**: Seed idea -> script + character manifest.
2.  **Panelization**: Script -> 8 distinct 16:9 panels with descriptions.
3.  **Image Synthesis**: Panel descriptions -> AI generated images (Imagen 4.0).
4.  **Assembly**: Images + Script -> responsive HTML layout (`output/comic.html`).
5.  **Inspection (Agent4)**: Summarize and export to ADK Artifacts.
