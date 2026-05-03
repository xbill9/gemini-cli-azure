# Copyright 2026 Google LLC
#
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

import logging

# Robust import of A2A constants
try:
    from a2a.utils.constants import AGENT_CARD_WELL_KNOWN_PATH, DEFAULT_RPC_URL
except ImportError:
    try:
        from a2a.utils import AGENT_CARD_WELL_KNOWN_PATH, DEFAULT_RPC_URL
    except ImportError:
        # Fallback to defaults if imports fail
        AGENT_CARD_WELL_KNOWN_PATH = "/.well-known/agent-card.json"
        DEFAULT_RPC_URL = "/rpc"

# Optional constants that might be missing in older versions
try:
    from a2a.utils.constants import EXTENDED_AGENT_CARD_PATH
except ImportError:
    try:
        from a2a.utils import EXTENDED_AGENT_CARD_PATH
    except ImportError:
        EXTENDED_AGENT_CARD_PATH = "/.well-known/agent-card-extended.json"

try:
    from a2a.utils.constants import PREV_AGENT_CARD_WELL_KNOWN_PATH
except ImportError:
    try:
        from a2a.utils import PREV_AGENT_CARD_WELL_KNOWN_PATH
    except ImportError:
        PREV_AGENT_CARD_WELL_KNOWN_PATH = "/a2a/agent/.well-known/agent-card.json"


from starlette.middleware.base import RequestResponseEndpoint
from starlette.requests import Request as StarletteRequest
from starlette.responses import Response

logger = logging.getLogger(__name__)


async def a2a_card_dispatch(
    request: StarletteRequest, call_next: RequestResponseEndpoint
) -> Response:
    """Middleware to dynamically update the agent card URL.

    This ensures that the agent card always points to the correct external URL
    of the service, which is necessary for A2A communication in environments
    like Cloud Run or Azure Container Apps where the URL is assigned dynamically.
    """
    path = request.url.path
    if (
        path.endswith(AGENT_CARD_WELL_KNOWN_PATH)
        or path.endswith(EXTENDED_AGENT_CARD_PATH)
        or path.endswith(PREV_AGENT_CARD_WELL_KNOWN_PATH)
    ):
        response = await call_next(request)
        if response.status_code == 200:
            # We need to read the body, but it might be large (though agent cards are small)
            if hasattr(response, "body_iterator"):
                body = b""
                async for chunk in response.body_iterator:
                    body += chunk
            else:
                body = response.body

            import json

            try:
                card = json.loads(body.decode())
                # Update the URL using the current request's host
                forwarded_host = request.headers.get("x-forwarded-host")
                forwarded_proto = request.headers.get("x-forwarded-proto", "https")

                if forwarded_host:
                    base_url = f"{forwarded_proto}://{forwarded_host}"
                    card["url"] = f"{base_url}{DEFAULT_RPC_URL}"
                    logger.debug(f"Updated agent card URL to: {card['url']}")

                return Response(
                    content=json.dumps(card),
                    status_code=response.status_code,
                    headers=dict(response.headers),
                    media_type=response.media_type,
                )
            except Exception as e:
                logger.error(f"Failed to process agent card: {e}")
                # Return original body if processing fails
                return Response(
                    content=body,
                    status_code=response.status_code,
                    headers=dict(response.headers),
                    media_type=response.media_type,
                )

    return await call_next(request)
