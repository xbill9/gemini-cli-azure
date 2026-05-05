import os

from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

from . import tools

# --- Example Agent using Azure AI Foundry (Phi-4-mini) ---

# Deployment name for Azure AI Foundry.
# Phi-4-mini is a highly capable SLM (Small Language Model) from Microsoft.
# Required environment variables: AZURE_AI_API_KEY, AZURE_AI_API_BASE
azure_model = os.getenv("AZURE_MODEL", "azure_ai/phi-4-mini")
azure_api_base = os.getenv("AZURE_AI_API_BASE")

# Robustness: Strip '/score' if it was incorrectly included in the base URL
if azure_api_base and azure_api_base.endswith("/score"):
    azure_api_base = azure_api_base[:-6]

root_agent = LlmAgent(
    model=LiteLlm(
        model=azure_model,
        api_base=azure_api_base,
        num_retries=3,
        request_timeout=30,
    ),
    name="azure_agent",
    instruction="""You are a professional cross-platform developer specializing in Microsoft Azure.
You can help users manage their Azure resources using the provided tools.
Always provide clear, well-formatted information and help users understand their cloud infrastructure.
""",
)
