#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "Ruler Sandbox - Local Development Setup"
echo "=========================================="
echo ""

# Check if task is installed
if ! command -v task &> /dev/null; then
    echo "Error: Task is not installed. Install it first:"
    echo "  https://taskfile.dev/installation/"
    exit 1
fi

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed. Install it first:"
    echo "  https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Install it first:"
    echo "  https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed. Install it first:"
    echo "  https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "All dependencies are installed!"
echo ""

# Show available commands
echo "Available commands:"
echo ""
task --list
