import logging
import sys
import os

from pythonjsonlogger.json import JsonFormatter
from fastmcp import FastMCP
from starlette.responses import JSONResponse
import azure.functions as func

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)  # Set the root logger level
formatter = JsonFormatter()

# Handler for all levels to stderr
stderr_handler = logging.StreamHandler(sys.stderr)
stderr_handler.setFormatter(formatter)
stderr_handler.setLevel(logging.INFO)  # Capture all levels from INFO up
logger.addHandler(stderr_handler)

# Initialize FastMCP server with HTTP transport
mcp = FastMCP(
    "hello-world-server"
)


# health check on standard http endpoint
@mcp.custom_route("/health", methods=["GET"])
async def health_check(request):
    return JSONResponse({"status": "healthy", "service": "mcp-server"})


@mcp.custom_route("/ping", methods=["GET"])
async def ping_route(request):
    return JSONResponse({"message": "pong"})


@mcp.tool()
def greet(param: str) -> str:
    """
    Get a greeting from a local stdio server.
    """
    logger.debug("Executed greet tool")
    # FastMCP automatically wraps the return value in TextContent
    return f"Hello, {param}!"


@mcp.resource("config://app")
def get_config() -> str:
    """
    Get the application configuration.
    """
    return "Application version: 1.0.0\nEnvironment: Azure Functions"


@mcp.prompt("generate-greeting")
def generate_greeting(name: str) -> str:
    """
    Generate a template for a greeting message.
    """
    return f"Please write a polite greeting for {name}. Mention that you are an MCP server running on Azure Functions."


# Export the ASGI app for Azure Functions
app = func.AsgiFunctionApp(
    app=mcp.http_app(stateless_http=True),
    http_auth_level=func.AuthLevel.ANONYMOUS
)


if __name__ == "__main__":
    # If PORT is set, run with HTTP transport (useful for containers/local testing)
    if "PORT" in os.environ:
        port = int(os.environ["PORT"])
        logger.info(f"🚀 MCP server started on port {port} (HTTP)")
        mcp.run(
            transport="http",
            host="0.0.0.0",
            port=port,
            stateless_http=True,
        )
    else:
        # Default to stdio for CLI integration
        mcp.run(transport="stdio")
