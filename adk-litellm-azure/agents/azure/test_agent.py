import unittest
from unittest.mock import MagicMock, patch
import os

# Set dummy env vars for LiteLlm initialization if needed
os.environ["AZURE_AI_API_KEY"] = "dummy-key"
os.environ["AZURE_AI_API_BASE"] = "https://dummy.inference.ai.azure.com"

from .agent import root_agent

class TestAzureAgent(unittest.TestCase):
    def test_agent_configuration(self):
        self.assertEqual(root_agent.name, "azure_agent")
        self.assertIn("Azure", root_agent.instruction)
        self.assertEqual(len(root_agent.tools), 3)
        tool_names = [t.__name__ for t in root_agent.tools]
        self.assertIn("list_azure_resource_groups", tool_names)
        self.assertIn("list_azure_storage_accounts", tool_names)
        self.assertIn("list_azure_vms", tool_names)

if __name__ == "__main__":
    unittest.main()
