# Microsoft Fabric MCP Context (Python)

This project is a **Python-based Model Context Protocol (MCP) server** optimized for **Microsoft Fabric**.

## Architecture

- **Backend:** Python 3.13 + `FastMCP` (HTTP transport).
- **Compute:** **Azure Container Apps (ACA)** (recommended for Fabric integrations).
- **Auth:** `azure-identity` (`DefaultAzureCredential`) for seamless integration with Fabric and Azure.

## Key Deployment Commands

- `make deploy`: Full deployment to Azure Container Apps.
- `make status`: Check ACA provisioning and FQDN.
- `make endpoint`: Get the current HTTPS FQDN.

## Fabric Integration Tips

1.  **Workload Manifest:** Use the FQDN from `make endpoint` in your `WorkloadManifest.xml` `BackendEndpoint`.
2.  **Entra ID:** The server uses `DefaultAzureCredential`. Ensure the ACA Managed Identity has necessary permissions (e.g., `Fabric.Extend`, `Storage Blob Data Contributor`).
3.  **OneLake Access:** Use the `azure-identity` credential to access OneLake via the DFS endpoints.

## Development

- Local: Run `python main.py` after `az login`.
- Remote: Use the ACA FQDN in your MCP client (e.g., Claude Desktop, Cursor).
