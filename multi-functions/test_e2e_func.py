import asyncio
import websockets
import json
import os
import sys

async def test_ws():
    # Use the provided URL or default to localhost
    host = os.getenv("FUNC_HOST")
    if not host:
        if len(sys.argv) > 1:
            host = sys.argv[1]
        else:
            print("Error: No host provided. Set FUNC_HOST env var or pass as argument.")
            sys.exit(1)

    # Remove protocol if present
    host = host.replace("http://", "").replace("https://", "").replace("ws://", "").replace("wss://", "")
    
    uri = f"wss://{host}/ws/e2e-user/e2e-session"
    print(f"Connecting to: {uri}")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("Successfully connected to Azure Function WebSocket")

            # Expecting a config message first
            msg = await websocket.recv()
            data = json.loads(msg)
            print(f"Received initial message: {json.dumps(data, indent=2)}")
            
            if data.get("type") == "config":
                print("PASSED: Received server config")
            else:
                print("FAILED: Expected config message")
                sys.exit(1)

            # Send Neural Handshake to wake up the model
            await websocket.send(json.dumps({"type": "text", "text": "Neural handshake"}))
            print("Sent Neural handshake")

            # Listen for responses (audio, transcript, etc.)
            print("Waiting for model response (approx 10s)...")
            
            received_audio = False
            received_transcript = False
            
            # Wait for up to 15 seconds for some output
            start_time = asyncio.get_event_loop().time()
            while asyncio.get_event_loop().time() - start_time < 15:
                try:
                    msg = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    data = json.loads(msg)
                    print(f"Received message keys: {list(data.keys())}")
                    
                    if "serverContent" in data or "server_content" in data:
                        content = data.get("serverContent") or data.get("server_content")
                        model_turn = content.get("modelTurn") or content.get("model_turn")
                        if model_turn:
                            for part in model_turn.get("parts", []):
                                if "inlineData" in part:
                                    received_audio = True
                                    print(f"Received Audio Data: {len(part['inlineData']['data'])} bytes")
                                if "text" in part:
                                    print(f"Received Text Part: {part['text']}")
                    
                    if "outputAudioTranscription" in data:
                        transcript = data["outputAudioTranscription"].get("finalTranscript")
                        if transcript:
                            received_transcript = True
                            print(f"Received Transcript: {transcript}")
                            
                except asyncio.TimeoutError:
                    continue
                except Exception as e:
                    print(f"Warning: {e}")
                    break

            if received_audio:
                print("PASSED: Received native audio from Gemini")
            else:
                print("FAILED: No audio received from Gemini")
                sys.exit(1)

            print("E2E Test completed successfully!")

    except Exception as e:
        print(f"E2E Test Failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(test_ws())
