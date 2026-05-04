# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm
from google.adk.tools.mcp_tool import MCPToolset, StreamableHTTPConnectionParams

# Fetch the MCP server URL from an environment variable
MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL")
if not MCP_SERVER_URL:
    raise ValueError("MCP_SERVER_URL environment variable not set.")


# Initialize MCP Toolset.
mcp_tools = MCPToolset(
    connection_params=StreamableHTTPConnectionParams(
        url=MCP_SERVER_URL
    )
)

root_agent = LlmAgent(
    model=LiteLlm(model=os.environ.get("AZURE_MODEL", "azure/gpt-5-nano")),
    name="devops",
    instruction="You are a management agent for infrastructure services.",
    tools=[mcp_tools]
)
