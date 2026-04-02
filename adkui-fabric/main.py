# main.py

import asyncio
import logging
import sys
import os
import re
import base64

from pythonjsonlogger.json import JsonFormatter
from fastmcp import FastMCP
from starlette.responses import JSONResponse
from azure.identity import DefaultAzureCredential
from google.adk import Agent

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
    "adk-comic-fabric-server"
)

# Load the ADK Studio Director Agent (Agent 3)
try:
    studio_director = Agent.from_yaml("Agent3/root_agent.yaml")
    logger.info("ADK Studio Director loaded successfully")
except Exception as e:
    logger.error(f"Failed to load ADK Studio Director: {e}")
    studio_director = None

# Health check on standard http endpoint
@mcp.custom_route("/health", methods=["GET"])
async def health_check(request):
    return JSONResponse({"status": "healthy", "service": "adk-comic-fabric"})

@mcp.tool()
async def create_comic(prompt: str) -> str:
    """
    Generate a full comic book from a seed idea.
    
    Args:
        prompt: The seed idea or story for the comic (e.g., "Create me a comic of a space cat").
    """
    if not studio_director:
        return "Error: ADK Studio Director not loaded."
    
    logger.info(f"Generating comic for prompt: {prompt}")
    try:
        # We ensure the prompt has the required prefix for the Studio Director
        if not prompt.lower().startswith("create me a comic of"):
            full_prompt = f"Create me a comic of {prompt}"
        else:
            full_prompt = prompt
            
        response = await studio_director.arun(full_prompt)
        return str(response.text)
    except Exception as e:
        logger.error(f"Failed to generate comic: {e}")
        return f"Error generating comic: {e}"

@mcp.tool()
def list_comics() -> str:
    """
    Lists the generated comics in the output directory.
    """
    output_dir = "output"
    if not os.path.exists(output_dir):
        return "No comics have been generated yet."
    
    files = [f for f in os.listdir(output_dir) if f.endswith(".html")]
    if not files:
        return "No HTML comics found in output directory."
    
    return "Generated comics:\n- " + "\n- ".join(files)

@mcp.tool()
def get_comic_summary() -> str:
    """
    Provides a summary of the latest generated comic.
    """
    html_path = os.path.join("output", "comic.html")
    if not os.path.exists(html_path):
        return "Error: 'output/comic.html' was not found."
    
    try:
        with open(html_path, "r") as f:
            content = f.read()
        
        # Simple extraction of text - stripping tags
        text_content = re.sub('<[^<]+?>', '\n', content)
        lines = [line.strip() for line in text_content.split('\n') if line.strip()]
        summary = "\n".join(lines[:20]) # Limit to first 20 lines
        
        return f"Summary of the comic:\n\n{summary}"
    except Exception as e:
        return f"Error reading comic file: {e}"

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    logger.info(f"🚀 ADK Fabric MCP server started on port {port}")
    
    mcp.run(
        transport="http",
        host="0.0.0.0",
        port=port,
    )
