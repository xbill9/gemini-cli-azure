#!/bin/bash
# Wrapper script for Azure Container Instance (ACI) deployment using Makefile

if [[ "$1" == "--status" ]]; then
    make az-status-aci
elif [[ "$1" == "--logs" ]]; then
    make az-logs-aci
elif [[ "$1" == "--destroy" ]]; then
    make az-destroy-aci
else
    make deploy-aci
fi
