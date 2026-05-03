#!/bin/bash
# judge_test.sh - Quick test for Judge agent

PORT=${1:-8002}
FINDINGS=${2:-"The internet started as ARPANET in the late 1960s."}

echo "Testing Judge agent on port $PORT..."
curl -s -X POST "http://localhost:$PORT/a2a/judge/invoke" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"Evaluate these findings: $FINDINGS\", \"user_id\": \"test_user\"}" \
  --no-buffer
echo -e "\nTest complete."
