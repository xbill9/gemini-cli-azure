import os
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

# --- Example Agent using Amazon Bedrock ---

# Model name for Azure
azure_model = os.getenv("AZURE_MODEL", "azure/gpt-5-nano")

root_agent = LlmAgent(
    model=LiteLlm(
        model=azure_model
    ),
    name="azure_agent",
    instruction="You are a helpful assistant powered by Azure OpenAI.",
    # ... other agent parameters
)

