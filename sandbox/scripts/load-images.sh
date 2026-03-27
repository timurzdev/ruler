#!/bin/bash
set -e

echo "Loading local Docker images into kind cluster..."
echo ""

if docker image inspect ruler-server:latest &>/dev/null; then
    echo "Loading ruler-server:latest..."
    kind load docker-image ruler-server:latest --name=ruler
else
    echo "Warning: ruler-server:latest not found in local Docker"
fi

if docker image inspect ruler-controller:latest &>/dev/null; then
    echo "Loading ruler-controller:latest..."
    kind load docker-image ruler-controller:latest --name=ruler
else
    echo "Warning: ruler-controller:latest not found in local Docker"
fi

echo ""
echo "Done!"
