#!/bin/bash
# Startup script for Biometric Security System
echo "Starting Biometric Security System Backend..."
echo "Local URL: http://127.0.0.1:8080/"

# Use relative paths or dynamic current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/backend"
python app/main.py
