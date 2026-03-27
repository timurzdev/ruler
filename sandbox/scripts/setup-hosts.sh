#!/bin/bash

# Script to setup local /etc/hosts entry for grafana.local

echo "========================================"
echo "Setup hosts file for local development"
echo "========================================"
echo ""
echo "Add the following line to your /etc/hosts file:"
echo ""
echo "127.0.0.1 grafana.local"
echo ""
echo "You can do this manually or run:"
echo "  echo '127.0.0.1 grafana.local' | sudo tee -a /etc/hosts"
echo ""
echo "After setup, Grafana will be available at:"
echo "  http://grafana.local:8080"
echo ""
