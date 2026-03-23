#!/bin/bash
# Wrapper script for Azure deployment using Makefile

if [[ "$1" == "--status" ]]; then
    make az-status
elif [[ "$1" == "--logs" ]]; then
    make az-logs
else
    make deploy-azure
fi
