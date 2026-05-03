#!/bin/bash
# research_test.sh - Quick test for Researcher agent

PORT=${1:-8001}
MESSAGE=${2:-"Research the history of the internet."}

echo "Testing Researcher agent on port $PORT..."
curl -s -X POST "http://localhost:$PORT/a2a/researcher/invoke" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"$MESSAGE\", \"user_id\": \"test_user\"}" \
  --no-buffer
echo -e "\nTest complete."
