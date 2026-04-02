#!/bin/bash
# Wrapper script for Azure Container Instance (ACI) deployment using Makefile

if [[ "$1" == "--status" ]]; then
    make status
elif [[ "$1" == "--logs" ]]; then
    make logs
elif [[ "$1" == "--destroy" ]]; then
    make destroy
else
    make deploy
fi
