#!/bin/bash
# Wrapper script for Azure deployment using Makefile

if [[ "$1" == "--aci" ]]; then
    if [[ "$2" == "--status" ]]; then
        make az-status-aci
    elif [[ "$2" == "--logs" ]]; then
        make az-logs-aci
    elif [[ "$2" == "--destroy" ]]; then
        make az-destroy-aci
    else
        make deploy-aci
    fi
elif [[ "$1" == "--status" ]]; then
    make az-status
elif [[ "$1" == "--logs" ]]; then
    make az-logs
else
    make deploy-azure
fi
