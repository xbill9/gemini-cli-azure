import logging
import os
from fastapi import FastAPI
from google.adk.cli import fast_api
from pathlib import Path

logger = logging.getLogger(__name__)

def get_stacked_app() -> FastAPI:
    """Returns a consolidated FastAPI app with all agents mounted."""
    from main import app as main_app
    
    # Base directory for agents
    base_dir = Path(__file__).parent.parent
    agents_dir = base_dir / "agents"
    
    # List of agents to mount
    agents = ["researcher", "judge", "content_builder", "orchestrator"]
    
    for agent_name in agents:
        agent_path = agents_dir / agent_name
        if not agent_path.exists():
            logger.warning(f"Agent directory not found: {agent_path}")
            continue
            
        logger.info(f"Mounting agent: {agent_name} at /{agent_name}")
        
        # Get the individual agent app
        # We use a2a=True to ensure A2A routes are registered
        agent_app = fast_api.get_fast_api_app(
            agents_dir=str(agents_dir),
            a2a=True,
            # We need to tell it which agent to load specifically
            # The ADK loader usually lists agents in the dir, but here we want one
        )
        
        # NOTE: mounting might conflict with A2A internal path assumptions
        # Alternative: manually register the agent in the main app's A2A registry if possible
        # But mounting is more standard for FastAPI.
        main_app.mount(f"/{agent_name}", agent_app)
        
    return main_app
