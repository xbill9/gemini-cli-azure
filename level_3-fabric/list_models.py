import os
from google.genai import Client
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    with open(os.path.expanduser("~/gemini.key"), "r") as f:
        api_key = f.read().strip()

client = Client(api_key=api_key)

print("Listing models:")
for model in client.models.list():
    if "live" in model.name.lower() or "flash" in model.name.lower():
        print(f"Name: {model.name}, Supported Actions: {model.supported_actions}")
