# main.py

import asyncio
import logging
import sys
import os

from pythonjsonlogger.json import JsonFormatter
from fastmcp import FastMCP
from starlette.responses import JSONResponse
from azure.identity import DefaultAzureCredential

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = JsonFormatter()

# Handler for all levels to stderr
stderr_handler = logging.StreamHandler(sys.stderr)
stderr_handler.setFormatter(formatter)
stderr_handler.setLevel(logging.INFO)
logger.addHandler(stderr_handler)

# Initialize Azure Credentials for Fabric integration
try:
    credential = DefaultAzureCredential()
    logger.info("Azure Credentials initialized for Fabric integration")
except Exception as e:
    logger.error(f"Failed to initialize Azure Credentials: {e}")

# Initialize FastMCP server with HTTP transport
mcp = FastMCP(
    "fabric-mcp-server"
)


# health check on standard http endpoint
@mcp.custom_route("/health", methods=["GET"])
async def health_check(request):
    return JSONResponse({"status": "healthy", "service": "mcp-server"})


@mcp.tool()
def greet(param: str) -> str:
    """
    Get a greeting from a local stdio server.
    """
    logger.debug("Executed greet tool")
    # FastMCP automatically wraps the return value in TextContent
    return param


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    logger.info(f"🚀 MCP server started on port {port}")
    
    mcp.run(
        transport="http",
        host="0.0.0.0",
        port=port,
    )

