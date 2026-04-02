#!/bin/bash
# Wrapper script for Azure Container Apps deployment (Fabric integration)

if [[ "$1" == "--status" ]]; then
    make az-status
elif [[ "$1" == "--logs" ]]; then
    make az-logs
elif [[ "$1" == "--endpoint" ]]; then
    make endpoint
else
    make deploy
fi
