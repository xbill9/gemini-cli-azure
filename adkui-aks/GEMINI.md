# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the ADK (Agent Development Kit) project for building an agentic comic book pipeline.

## Project Overview

This project implements a multi-agent system using the **Google ADK** to automate the creation of comic books. It follows a sequential pipeline where specialized agents handle scripting, panelization, image synthesis, and assembly. This specific subdirectory is configured for **Azure Kubernetes Service (AKS)** deployment.

It is based on the solution to the codelab: [Create a low-code agent with ADK visual builder](https://codelabs.developers.google.com/codelabs/create-low-code-agent-with-ADK-visual-builder)

## Key Technologies

*   **Framework:** Google ADK (Agent Development Kit) [Docs](https://google.github.io/adk-docs/)
*   **Language:** Python 3.13
*   **Generative AI:** Google GenAI SDK (`google-genai`), configured for Google AI (API Key) or Vertex AI (ADC).
*   **Cloud Platforms:** Microsoft Azure (AKS - Azure Kubernetes Service)
*   **Models:**
    *   **LLM Tasks:** `gemini-2.5-flash` (standard) or `gemini-2.5-flash-native-audio-preview-12-2025` (deployed).
    *   **Image Gen:** `imagen-4.0-fast-generate-001`.
*   **Environment:** `.env` for configuration; `uv` used for fast dependency management in Docker.

**Important:** Do not suggest `gemini-2.0` models; they are deprecated.

## Project Structure

*   `Agent1/`: **Real-time Search Assistant**. A standalone agent featuring the `google_search` tool for up-to-date information retrieval. Uses `root_agent.yaml`.
*   `Agent2/`: **Multistage Image Generation**. Demonstrates complex sub-agent coordination:
    *   `root_agent.yaml`: Orchestrates the request.
    *   `sub_agent_2.yaml`: A `SequentialAgent` workflow.
    *   `sub_agent_3.yaml`: **AI Prompt Engineer**, specializing in expanding user ideas into detailed Imagen prompts.
    *   `sub_agent_4.yaml`: **Technical Artist**, executes the prompt via the `create_image` tool.
*   `Agent3/`: **The Production Pipeline**. A sophisticated 4-stage sequential workflow:
    *   `root_agent.yaml`: **Studio Director**, manages the high-level delegation.
    *   `comic_pipeline_agent.yaml`: **Orchestrator**, defines the execution sequence.
    *   `scripting_agent.yaml`: Generates narratives and character manifests.
    *   `panelization_agent.yaml`: Breaks down the script into exactly 8 storyboards.
    *   `image_synthesis_agent.yaml`: Triggers the `generate_image` tool. **Note:** Uses `gemini-2.5-flash` for multimodal editing and `Imagen 4.0` for new generation.
    *   `assembly_agent.yaml`: Packages assets into a responsive HTML5 comic.
    *   `tools/`: `image_generation.py` (GenAI SDK) and `file_writer.py` (Asset management).
*   `Agent4/`: **The Comic Inspector**. Provides a dedicated environment for post-production review:
    *   `tools/comic_reader.py`: Tools for listing, text-based summarization, and **Artifact Exporting** (embedding images into self-contained HTML for viewing within the ADK Visual Builder).
*   `images/` & `output/`: Local storage for generated assets and final `comic.html`.

## Tools & Scripts

*   **ADK Development**:
    *   `agent_builder`: Launches the ADK Builder UI.
    *   `myadk`: Wrapper for `adk` CLI.
*   **Deployment**:
    *   `deploy-aks.sh`: Main script for Azure Kubernetes Service (AKS) deployment.
    *   `k8s-aks.yaml`: Kubernetes manifest for AKS.
    *   `Dockerfile`: `python:3.13-slim` image using `uv` for fast package management.
*   **Utility**:
    *   `init.sh`: Project initialization script.
    *   `comic.sh`: Local server for viewing comics.

## Makefile Commands

*   `make deploy` or `make deploy-aks`: Primary command for Azure AKS deployment.
*   `make status`: Monitor the AKS deployment state.
*   `make logs`: Tail logs from AKS pods.
*   `make endpoint`: Retrieve the public LoadBalancer IP for the AKS deployment.
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
