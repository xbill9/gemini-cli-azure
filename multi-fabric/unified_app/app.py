import json
import logging
import os
import re

# Suppress experimental warnings
import warnings
from collections.abc import AsyncGenerator
from typing import Any

import httpx
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles

# ADK imports
from google.adk.cli import fast_api as adk_fast_api
from httpx_sse import aconnect_sse
from pydantic import BaseModel

# Import shared configurations
from shared.logging_config import get_uvicorn_log_config, setup_logging

warnings.filterwarnings("ignore", message=r".*\[EXPERIMENTAL\].*", category=UserWarning)
os.environ["ADK_SUPPRESS_EXPERIMENTAL_FEATURE_WARNINGS"] = "True"

# Standardized logging setup
setup_logging("course-creator-unified")
logger = logging.getLogger(__name__)

# --- FastAPI App Setup ---
# We build the ADK FastAPI app, pointing it to the agents directory
agents_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "agents"))

app = adk_fast_api.get_fast_api_app(
    agents_dir=agents_dir,
    web=False, # We'll provide our own web UI
    a2a=False, # No longer needed, everything is in-memory
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SimpleChatRequest(BaseModel):
    message: str
    user_id: str = "test_user"
    session_id: str | None = None

# We hit ourselves to run the SSE.
LOCAL_PORT = int(os.getenv("PORT", 8080))
LOCAL_URL = f"http://127.0.0.1:{LOCAL_PORT}"

async def create_session(user_id: str) -> dict[str, Any]:
    async with httpx.AsyncClient() as client:
        response = await client.post(f"{LOCAL_URL}/apps/orchestrator/users/{user_id}/sessions")
        response.raise_for_status()
        return response.json()

async def get_session(user_id: str, session_id: str) -> dict[str, Any] | None:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{LOCAL_URL}/apps/orchestrator/users/{user_id}/sessions/{session_id}")
        if response.status_code == 404:
            return None
        response.raise_for_status()
        return response.json()

async def query_adk_server_local(user_id: str, message: str, session_id: str) -> AsyncGenerator[dict[str, Any]]:
    request = {
        "appName": "orchestrator",
        "userId": user_id,
        "sessionId": session_id,
        "newMessage": {"role": "user", "parts": [{"text": message}]},
        "streaming": True,
    }

    timeout = httpx.Timeout(60.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        try:
            async with aconnect_sse(client, "POST", f"{LOCAL_URL}/run_sse", json=request) as event_source:
                if event_source.response.status_code != 200:
                    await event_source.response.aread()
                    logger.error(f"Error from ADK: {event_source.response.status_code} - {event_source.response.text}")
                    yield {"author": "orchestrator", "content": {"parts": [{"text": f"❌ Server Error: {event_source.response.status_code}"}]}}
                    return

                async for server_event in event_source.aiter_sse():
                    try:
                        yield server_event.json()
                    except Exception as e:
                        logger.error(f"Failed to parse SSE event: {e}")
        except Exception as e:
            logger.error(f"SSE connection failed: {e}")
            yield {"author": "orchestrator", "content": {"parts": [{"text": f"❌ Connection Failed: {e}"}]}}

def extract_all_text(event_obj: dict[str, Any]) -> list[str]:
    if not isinstance(event_obj, dict):
        return []
    texts = []
    content = event_obj.get("content")
    if isinstance(content, dict):
        parts = content.get("parts")
        if isinstance(parts, list):
            for part in parts:
                if isinstance(part, dict) and "text" in part:
                    texts.append(part["text"])
    return texts

def merge_strings(existing: str, incoming: str) -> str:
    if not existing:
        return incoming
    if not incoming:
        return existing
    e_norm = existing.rstrip()
    i_norm = incoming.lstrip()
    if not i_norm:
        return existing
    max_overlap = min(len(e_norm), len(i_norm), 500)
    for size in range(max_overlap, 0, -1):
        if e_norm.endswith(i_norm[:size]):
            return existing + incoming[incoming.find(i_norm[:size]) + size :]
    return existing + incoming

def cleanup_final_text(text: str) -> str:
    text = re.sub(r"🚀\s*Starting the course creation pipeline\.\.\.", "", text)
    text = re.sub(r"✍️\s*Building the final course content\.\.\.", "", text)
    text = re.sub(r"🔍\s*Research is starting\.\.\.", "", text)
    text = re.sub(r"⚖️\s*Judge is evaluating findings\.\.\.", "", text)
    text = re.sub(r"\[progress_.*\]\s*said:?", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\[capture_.*\]\s*said:?", "", text, flags=re.IGNORECASE)
    text = re.sub(r"For context:?", "", text, flags=re.IGNORECASE)
    return text.strip()

@app.post("/api/chat_stream")
async def chat_stream(request: SimpleChatRequest):
    session = None
    if request.session_id:
        session = await get_session(request.user_id, request.session_id)
    if session is None:
        session = await create_session(request.user_id)

    events = query_adk_server_local(request.user_id, request.message, session["id"])

    async def event_generator():
        final_text = ""
        yield json.dumps({"type": "progress", "text": "🚀 Connected, starting research..."}) + "\n"

        async for event in events:
            author = event.get("author", "")
            if error_msg := event.get("errorMessage"):
                yield json.dumps({"type": "progress", "text": f"❌ Error from {author}: {error_msg}"}) + "\n"
                continue

            event_text = "".join(extract_all_text(event))
            if not event_text:
                continue

            if author.startswith("progress_"):
                yield json.dumps({"type": "progress", "text": event_text.strip()}) + "\n"
                continue
            elif author == "researcher":
                yield json.dumps({"type": "progress", "text": "🔍 Researcher is gathering information..."}) + "\n"
            elif author == "judge":
                yield json.dumps({"type": "progress", "text": "⚖️ Judge is evaluating findings..."}) + "\n"
            elif author == "content_builder":
                yield json.dumps({"type": "progress", "text": "✍️ Content Builder is writing the course..."}) + "\n"
                final_text = merge_strings(final_text, event_text)

        yield json.dumps({"type": "result", "text": cleanup_final_text(final_text)}) + "\n"

    return StreamingResponse(event_generator(), media_type="application/x-ndjson")

# Add health endpoint
@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

# Mount frontend
frontend_path = os.path.join(os.path.dirname(__file__), "..", "app", "dist")
if os.path.exists(frontend_path):
    app.mount("/", StaticFiles(directory=frontend_path, html=True), name="frontend")
else:
    logger.warning(f"Frontend dist not found at {frontend_path}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run("unified_app.app:app", host="0.0.0.0", port=port, log_config=get_uvicorn_log_config(os.getenv("LOG_LEVEL", "info")))
