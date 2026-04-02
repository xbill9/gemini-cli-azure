# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the project and assist in development.

## Project Overview

Python-based **Model Context Protocol (MCP)** server using `FastMCP`. Deployed to **Azure Kubernetes Service (AKS)** over HTTP.

## Key Technologies

*   **Language:** Python 3.13 (containerized)
*   **Framework:** `FastMCP` (MCP SDK)
*   **Infrastructure:** Azure Kubernetes Service (AKS), Azure Container Registry (ACR)
*   **Logging:** `python-json-logger` to stderr

## Core Commands (Makefile)

### Local Development
- `make install`: Install Python dependencies.
- `make run`: Start the server locally (default port 8080).
- `make lint`: Run flake8 linting.

### Azure Infrastructure (One-time)
- `make az-login`: Login to Azure CLI.
- `make aks-create`: Create Resource Group, ACR, and AKS cluster.
- `make aks-get-credentials`: Configure kubectl for the AKS cluster.

### Deployment & Status
- `make deploy`: Build, push, and deploy the application to AKS.
- `make status`: Check AKS and Kubernetes resource status.
- `make endpoint`: Get the public IP of the LoadBalancer service.

### Cleanup
- `make aks-destroy`: Delete the AKS cluster only.
- `make az-destroy`: Delete the entire Resource Group and all assets.

## Project Structure

- `main.py`: FastMCP server definition and tools (`greet`).
- `k8s.yaml`: Kubernetes Deployment (port 8080) and LoadBalancer Service (port 80).
- `Makefile`: Automation for the entire lifecycle.
- `Dockerfile`: Multi-stage build (slim) for Python 3.13.

## Developer Notes
- Logs go to `stderr` to keep `stdout` clean for JSON-RPC messages.
- The `/health` endpoint is used for Kubernetes liveness/readiness probes.
- AKS deployment uses `sed` to inject the image tag into `k8s.yaml`.
