# Gemini Code Assistant Context (Fabric Edition)

This project implements a multi-agent system using the **Google ADK** to automate the creation of comic books, optimized for **Microsoft Fabric** as an MCP server.

## Project Overview

It follows a sequential pipeline where specialized agents handle scripting, panelization, image synthesis, and assembly. The project is deployed as an **Azure Container Apps (ACA)** backend for Microsoft Fabric.

## Key Technologies

*   **Framework:** Google ADK (Agent Development Kit) & **FastMCP** (HTTP transport).
*   **Language:** Python 3.13
*   **Generative AI:** Google GenAI SDK (`google-genai`).
*   **Cloud Platform:** Microsoft Azure (Azure Container Apps).
*   **Fabric Integration:** Uses `azure-identity` for Entra ID (managed identity) authentication.

## Project Structure

*   `main.py`: Entry point for the **FastMCP** server. It exposes ADK agents as MCP tools.
*   `Agent3/`: The primary comic production pipeline.
*   `Agent4/`: Tooling for inspecting and exporting results to the Fabric/ADK UI.
*   `Agent3/tools/`: Shared logic for `google-genai` image synthesis and artifact management.

## Deployment Strategy

Azure Container Apps (ACA) is the primary target. Deployment is automated via the `Makefile`.

*   `make deploy`: Builds the Docker image, pushes to ACR, and updates/creates the ACA instance.
*   `make endpoint`: Retrieves the public FQDN required for Fabric integration.
*   `make az-status`: Monitors the deployment health.

## Microsoft Fabric Integration

1.  **Transport:** FastMCP provides an HTTP-based MCP interface compatible with Fabric.
2.  **Authentication:** Uses `DefaultAzureCredential` to authenticate with Azure services and potentially Fabric workloads.
3.  **Workload Manifest:** The ACA FQDN should be configured in the Fabric workload manifest to enable tool discovery.
4.  **Exposed Tools:** `create_comic`, `list_comics`, and `get_comic_summary` are available via the MCP endpoint.

## Environment & Constraints

*   **Managed Identity:** The ACA instance must have a managed identity with access to ACR and (optionally) Google Cloud if using cross-cloud resources.
*   **Local Storage:** Disabled in ACA (`ADK_DISABLE_LOCAL_STORAGE=1`). Artifacts should be handled via memory or external storage if persistence beyond the container lifecycle is needed.
*   **Environment Variables:** Managed via `.env` locally and ACA secrets/env in production.
