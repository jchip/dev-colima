#!/bin/bash

set -e

echo "=== Colima Setup Script ==="
echo

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed."
    echo "Install it from https://brew.sh"
    exit 1
fi

# Check and install Colima
if ! command -v colima &> /dev/null; then
    echo "Installing Colima..."
    brew install colima
else
    echo "Colima is already installed: $(colima version | head -1)"
fi

# Check and install Docker CLI
if ! command -v docker &> /dev/null; then
    echo "Installing Docker CLI..."
    brew install docker
else
    echo "Docker CLI is already installed: $(docker --version)"
fi

# Check and install Lazydocker
if ! command -v lazydocker &> /dev/null; then
    echo "Installing Lazydocker..."
    brew install lazydocker
else
    echo "Lazydocker is already installed: $(lazydocker --version)"
fi

echo

# Check Colima status and start if needed
if colima status &> /dev/null; then
    echo "Colima is running"
    colima status
else
    echo "Colima is not running. Starting..."
    colima start
    echo
    echo "Colima started successfully"
fi

echo
echo "=== Verification ==="

# Verify Docker connection
if docker info &> /dev/null; then
    echo "Docker is connected and working"
    echo
    docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}'
else
    echo "Error: Docker is not responding"
    exit 1
fi

echo
echo "=== Setup Complete ==="
echo "You can now use 'docker' commands."
