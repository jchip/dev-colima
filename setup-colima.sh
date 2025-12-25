#!/bin/bash

# Options
INSTALL_PORTAINER=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --portainer)
            INSTALL_PORTAINER=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--portainer]"
            exit 1
            ;;
    esac
done

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

# Check and install Docker Compose
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    brew install docker-compose
else
    echo "Docker Compose is already installed: $(docker compose version --short)"
fi

# Check and install Lazydocker
if ! command -v lazydocker &> /dev/null; then
    echo "Installing Lazydocker..."
    brew install lazydocker
else
    echo "Lazydocker is already installed: $(lazydocker --version)"
fi

echo

# Start default profile (for development)
if ! colima status &> /dev/null; then
    echo "Starting default profile (dev)..."
    colima start
else
    echo "Default profile (dev) is running"
fi

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

echo
echo "=== Profiles ==="
colima list

echo
echo "=== Docker Contexts ==="
docker context ls

echo
echo "=== Fixing Docker Contexts ==="

# Get current default context endpoint
DEFAULT_ENDPOINT=$(docker context inspect default -f '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "")

# Check if the endpoint exists
if [ -n "$DEFAULT_ENDPOINT" ]; then
    # Extract socket path from unix:// endpoint
    SOCKET_PATH="${DEFAULT_ENDPOINT#unix://}"
    if [ ! -S "$SOCKET_PATH" ]; then
        echo "Default context endpoint doesn't exist: $SOCKET_PATH"
        echo "Updating default context to point to Colima default..."
        docker context update default --docker "host=unix://$HOME/.colima/default/docker.sock"
    else
        echo "Default context endpoint exists: $SOCKET_PATH"
    fi
else
    echo "Updating default context to point to Colima default..."
    docker context update default --docker "host=unix://$HOME/.colima/default/docker.sock"
fi

# Check if colima context exists, create if not
if ! docker context inspect colima &> /dev/null; then
    echo "Creating 'colima' context for default profile..."
    docker context create colima --docker "host=unix://$HOME/.colima/default/docker.sock"
else
    echo "'colima' context already exists"
fi

echo
echo "=== Verification ==="

# Verify Docker connection
if docker --context colima info &> /dev/null; then
    echo "Docker (dev/default) is connected and working"
else
    echo "Error: Docker (dev/default) is not responding"
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
if [ ! -L /var/run/docker.sock ] || [ "$(readlink /var/run/docker.sock)" != "$HOME/.colima/default/docker.sock" ]; then
    echo "Creating /var/run/docker.sock symlink to default profile (requires sudo)..."
    sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
    echo "Symlink created."
else
    echo "Socket symlink already configured"
fi

# Install Portainer (optional)
if [ "$INSTALL_PORTAINER" = true ]; then
    echo
    echo "=== Portainer Setup ==="
    if docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
        echo "Portainer container already exists"
        if ! docker ps --format '{{.Names}}' | grep -q "^portainer$"; then
            echo "Starting Portainer..."
            docker start portainer
        else
            echo "Portainer is running"
        fi
    else
        echo "Creating Portainer volume..."
        docker volume create portainer_data
        echo "Starting Portainer container..."
        docker run -d \
            --name portainer \
            --restart=always \
            -p 9000:9000 \
            -p 9443:9443 \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v portainer_data:/data \
            portainer/portainer-ce:latest
        echo "Portainer installed and running"
    fi
    echo "Access Portainer at: http://localhost:9000"
fi

echo
echo "=== Setup Complete ==="
echo
echo "Profiles:"
echo "  default  = Development (colima start)"
echo "  prod     = Production  (colima start --profile prod)"
echo
echo "Usage:"
echo "  docker ps                        # Uses dev (default)"
echo "  docker --context colima-prod ps  # Uses prod"
echo "  lazydocker                       # TUI for dev"
echo "  DOCKER_CONTEXT=colima-prod lazydocker  # TUI for prod"
echo
echo "Optional:"
echo "  $0 --portainer    # Install Portainer web UI"
