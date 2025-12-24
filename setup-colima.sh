#!/bin/bash

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

# Create prod profile if not exists
if ! colima status --profile prod &> /dev/null; then
    echo "Creating prod profile..."
    colima start --profile prod
else
    echo "Prod profile exists"
    # Start if not running
    if ! colima status --profile prod 2>&1 | grep -q "Running"; then
        echo "Starting prod profile..."
        colima start --profile prod
    fi
fi

# Create dev profile if not exists
if ! colima status --profile dev &> /dev/null; then
    echo "Creating dev profile..."
    colima start --profile dev
else
    echo "Dev profile exists"
    # Start if not running
    if ! colima status --profile dev 2>&1 | grep -q "Running"; then
        echo "Starting dev profile..."
        colima start --profile dev
    fi
fi

echo
echo "=== Profiles ==="
colima list

echo
echo "=== Docker Contexts ==="
docker context ls

echo
echo "=== Verification ==="

# Verify Docker connection
if docker --context colima-dev info &> /dev/null; then
    echo "Docker (dev) is connected and working"
else
    echo "Error: Docker (dev) is not responding"
    exit 1
fi

if docker --context colima-prod info &> /dev/null; then
    echo "Docker (prod) is connected and working"
else
    echo "Error: Docker (prod) is not responding"
    exit 1
fi

echo

# Create symlink for default context
if [ ! -L /var/run/docker.sock ] || [ "$(readlink /var/run/docker.sock)" != "$HOME/.colima/dev/docker.sock" ]; then
    echo "Creating /var/run/docker.sock symlink to dev profile (requires sudo)..."
    sudo ln -sf ~/.colima/dev/docker.sock /var/run/docker.sock
    echo "Symlink created. 'docker' commands now use dev profile by default."
else
    echo "Socket symlink already configured for dev profile"
fi

echo
echo "=== Setup Complete ==="
echo
echo "Usage:"
echo "  docker ps                        # Uses dev (default)"
echo "  docker --context colima-prod ps  # Uses prod"
echo "  lazydocker                       # TUI for dev"
echo "  DOCKER_CONTEXT=colima-prod lazydocker  # TUI for prod"
