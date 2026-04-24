# ADK & Gemini 3.1 Flash Live Developer Guide

Do not ever use any 2.0 models they are depreciated.
Suggest only 2.5 models or later

the recommended video frame rate is 2 per second

This document provides technical guidance for developers working with the Google Agent Development Kit (ADK) and the Gemini 3.1 Flash Live model within this project.

## Gemini 3.1 Flash Live Overview

Gemini 3.1 Flash Live is a low-latency, natively multimodal model optimized for real-time interactions. It is a specialized variant of the Gemini 3 Pro model family.

https://ai.google.dev/gemini-api/docs/live-api/capabilities

github has open issues:

https://github.com/livekit/agents-js/pull/1186
https://github.com/google/adk-python/issues/5075
https://github.com/google/adk-python/issues/5018

use this for skills:
https://github.com/google-gemini/gemini-skills/blob/main/skills/gemini-live-api-dev/SKILL.md

live model article
https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-1-flash-live/

audio implementation

https://developer.chrome.com/blog/audio-worklet

### Key Technical Specifications

-   **Model ID:** `gemini-3.1-flash-live-preview` (default in this project)
-   **Context Window:** 128K tokens (Input) / 64K tokens (Output).
-   **Modality:** Natively multimodal. Supports Text, Image, Audio, and Video as input; Text and Audio as output.
-   **Native Audio:** Directly processes and generates audio, preserving emotional nuance and pacing without external TTS/STT engines.
-   **Real-time Streaming:** Optimized for continuous data streams (video/audio) with "immediate" response latency.

### Use Case in This Project

The Biometric Security System leverages Gemini 3.1 Flash Live's **video streaming** and **complex function calling** capabilities to:
1.  Analyze a live video feed of hand gestures.
2.  Maintain a robotic, low-latency conversational persona.
3.  Execute the `report_digit` tool immediately upon visual verification of a gesture.
4.  Execute the `trigger_system_error` tool if an offensive gesture (middle finger) is detected.
5.  Execute the `trigger_heavy_metal_mode` tool if the "Devil's Horns" gesture is detected (secret override).

## Working with ADK (Agent Development Kit)

The backend uses the Google ADK to orchestrate the agent's behavior and tools.

### Gemini 3.1 Compatibility Patches (`backend/app/patch_adk.py`)

Since Gemini 3.1 Flash Live is a preview model with a slightly different API structure than Gemini 2.5, this project uses a monkey-patching utility to ensure compatibility:
- **`media_chunks` deprecation**: Gemini 3.1 moves away from `media_chunks` in favor of direct `audio`, `video`, and `text` parameters in `send_realtime_input`.
- **AudioCacheManager fix**: Patches the cache manager to handle `NoneType` edge cases during high-frequency streaming.
- **AsyncSession Unrolling**: Automatically unrolls legacy ADK `media` blobs into the correct Gemini 3.1 multimodal parameters.

The patch is applied automatically at startup in both `main.py` and `agent.py`.

### Agent Definition (`backend/app/biometric_agent/agent.py`)

Agents are defined using the `Agent` class, which encapsulates the model, instructions, and tools.

```python
from google.adk.agents import Agent

root_agent = Agent(
    name="biometric_agent",
    model=MODEL_ID,
    tools=[report_digit, trigger_system_error, trigger_heavy_metal_mode],
    instruction="..."
)
```

### Tool Implementation

Tools are standard Python functions with clear docstrings. Gemini uses these docstrings to understand when and how to call the tool.

-   **`report_digit(count: int)`**: Sends the detected finger count (1-5) to the system.
-   **`trigger_system_error()`**: Triggers a fatal error if an offensive gesture (middle finger) is detected.
    -   *Enforcement Detail*: The backend immediately terminates the WebSocket connection after sending the error signal to prevent further interaction.
-   **`trigger_heavy_metal_mode()`**: Activates the "Heavy Metal Authentication Override" if the "Devil's Horns" gesture is detected (index and pinky extended).
    -   *Implementation Detail*: The frontend (`BiometricLock.jsx`) triggers a custom audio event when this tool is executed, playing the "War Pigs" intro from a verified `archive.org` source.
-   **Critical Requirement:** Tool results should be handled as specified in the agent's instructions (e.g., "When you get the result of `report_digit`, DO NOT SPEAK").

### Runner and Session Service (`backend/app/main.py`)

The `Runner` connects the agent to the FastAPI application and manages the execution loop. The `InMemorySessionService` tracks state across multiple turns in a session.

### Model Selection & Fallback

The system intelligently selects the model ID based on the execution context:
-   **Default**: `gemini-3.1-flash-live-preview` (Optimized for WebSockets/Live API).
-   **Fallback**: `gemini-2.5-flash` is used automatically when running via `adk run` (CLI) to avoid 404 errors, as Gemini 3.1 Live Preview strictly requires the Multimodal Live API.

### WebSocket Integration & Proactivity

ADK provides a bidirectional streaming interface over WebSockets.

#### Binary Protocol
For maximum efficiency, the system uses a binary protocol for media streaming:
-   **Audio (0x01)**: Raw PCM 16kHz audio data.
-   **Video (0x02)**: JPEG encoded image frames (640x480).

#### Configuration & Stimuli
-   **Initial Config**: Upon connection, the server sends a `type: "config"` message specifying `video_fps` and `heartbeat_interval`.
-   **Native Audio Config**: For `gemini-3.1-flash-live-preview`, `response_modalities` should be set to `["AUDIO"]`.
-   **Proactivity Limitation**: **Gemini 3.1 Flash Live is not yet proactive.** It will not initiate speech or tool calls until it receives input (audio, video, or text).
-   **Neural Handshake**: The backend sends a "Neural handshake" text stimulus immediately after connection to "wake up" the model.
-   **Heartbeat Stimulus**: To prevent the model from idling during long periods of visual-only surveillance, a `CONTINUE_SURVEILLANCE` text stimulus is sent every 10 seconds if no other input is detected.
-   **Manual Greeting**: The backend manually sends a pre-recorded PCM audio greeting (`mock_audio.pcm`) to the client as soon as the WebSocket connects.

#### Neural Sync Status Messages
The backend communicates detected events via JSON over WebSocket:
-   `type: "match"`: Digit detected (`count`).
-   `type: "system_error"`: Offensive gesture detected.
-   `type: "heavy_metal"`: Devil's Horns detected.

## Developer Workflow

1.  **Instruction Tuning:** Modify the `instruction` string in `agent.py` to refine the scanner's behavior and personality.
2.  **Tool Expansion:** Add new functions to the `tools` list in `agent.py` to expand the system's capabilities.
3.  **Local Testing (Mock Server):** Use `mock.sh` to test the frontend and backend orchestration. The mock server sends `{"mock": true}`, triggering a yellow banner in the UI to indicate simulation mode.
4.  **Automated Testing**: Run `make test`. Note that async tests (like `test_live_connection.py`) require the `@pytest.mark.anyio` marker and the `anyio` plugin.
5.  **Deployment:** Ensure all environment variables (especially `MODEL_ID` and `GOOGLE_API_KEY`) are correctly set.
    -   **Manual Deployment (Container Apps)**: Use `make deploy` to deploy directly to Azure Container Apps (ACA).
        -   **Service Name**: `container-app`
        -   **Resource Group**: Default is `multi-functions-east`.
        -   **Location**: Default is `westus`.
        -   **Clean Up**: Use `make az-destroy` to remove the resource group and all associated Azure resources.
-   **Manual Deployment (Azure Functions)**: Use `make deploy-func` to deploy to Azure Functions (**on Container Apps**).
        -   **Service Name**: `azure-functions`
        -   **Resource Group**: Default is `multi-functions-east`.
        -   **Location**: Default is `eastus`.
        -   **Environment**: Uses a Container App Environment to support custom containers and WebSockets in a serverless model.
        -   **Endpoint**: Use `make func-endpoint` to retrieve the URL.
        -   **Clean Up**: Use `make func-destroy` to remove the resource group.

## Migrating from Gemini 2.5 Flash Live

Gemini 3.1 Flash Live Preview is optimized for low-latency, real-time dialogue.

- **Model string:** Update from `gemini-2.5-flash-native-audio-preview-12-2025` to `gemini-3.1-flash-live-preview`.
- **API Call migration:** `session.send` is deprecated. Use `session.send_realtime_input(text="...")` or `session.send_realtime_input(audio=...)` instead. (Verified in `test_live_connection.py`).
- **Thinking configuration:** Gemini 3.1 uses `thinkingLevel` (default: minimal) instead of `thinkingBudget`.
- **Server events:** A single event can contain multiple content parts (audio chunks + transcript).
- **Proactive audio:** Not yet supported in Gemini 3.1 Flash Live. Remove `ProactivityConfig` from your code and use stimuli to trigger model responses.

## Current System Status

- **Tests:** 8/8 tests passing (`make test`).
- **Linting:** 100% compliant with Ruff (Python) and ESLint (Frontend) (`make lint`).
- **Performance:** Optimized 2 FPS video stream using `toBlob` at 0.6 quality for minimal latency.

## Resources

-   [Gemini 3.1 Flash Live Model Card](https://deepmind.google/models/model-cards/gemini-3-1-flash-live/)
-   [Google ADK Documentation](https://github.com/google/adk) (Internal/Preview)
