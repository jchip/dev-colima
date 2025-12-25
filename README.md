# Colima Setup

Colima is a lightweight container runtime for macOS and Linux that provides Docker compatibility.

| Platform | Virtualization |
|----------|----------------|
| macOS | Native Virtualization.Framework |
| Linux | Native containers (no VM) |
| Windows | Not supported |

## Why Colima?

Colima is significantly lighter than Docker Desktop:

| Aspect | Colima | Docker Desktop |
|--------|--------|----------------|
| RAM (idle) | ~400-600 MB | ~2-4 GB |
| CPU (idle) | Minimal | Higher background usage |
| Startup | ~10 seconds | ~30+ seconds |
| Background processes | 1 (lima) | Multiple |
| Virtualization | Native macOS VZ | Custom VM |
| Updates | `brew upgrade` | Auto-updater, restarts |

## Dual Profile Setup

This setup uses two isolated Colima profiles (no Docker Desktop required):

| Profile | Context | Purpose | Access |
|---------|---------|---------|--------|
| default | `colima` | Development/ephemeral containers | `docker ...` |
| prod | `colima-prod` | Production/important containers | `docker --context colima-prod ...` |

This separation keeps production containers isolated from development experiments.

Using `default` for development means `colima start` always works without breaking the dev environment.

## Prerequisites

- macOS or Linux
- Homebrew (macOS) or package manager (Linux)

## Installation

Run the setup script:

```bash
./setup-colima.sh
```

This script will:
- Install Colima, Docker CLI, Docker Compose, and Lazydocker via Homebrew
- Create prod and dev profiles
- Start both profiles
- Create `/var/run/docker.sock` symlink to dev profile
- Verify the installation

## Manual Installation

```bash
brew install colima docker docker-compose lazydocker
colima start                   # Default profile (dev)
colima start --profile prod    # Prod profile
sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
```

## Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `colima start` | Start Colima VM |
| `colima stop` | Stop Colima VM |
| `colima status` | Check status |
| `colima delete` | Delete the VM |
| `colima ssh` | SSH into the VM |

### Start with Custom Resources

```bash
colima start --cpu 4 --memory 8 --disk 100
```

### Docker Commands

Once Colima is running, use Docker as usual:

```bash
docker ps
docker run -it ubuntu bash
docker-compose up
```

## Configuration

Default VM settings:
- **CPU**: 2 cores
- **Memory**: 2 GB
- **Disk**: 60 GB
- **Runtime**: Docker
- **Mount Type**: virtiofs

Edit configuration:

```bash
colima start --edit
```

## Multiple Profiles

Colima supports multiple isolated profiles. Each profile is a separate VM with its own containers, volumes, and networks.

### Create Profiles

```bash
colima start                    # Default profile (production)
colima start --profile dev      # Development profile
colima start --profile test     # Testing profile
```

### Manage Profiles

```bash
colima list                     # List all profiles
colima stop --profile dev       # Stop dev profile
colima delete --profile dev     # Delete dev profile
colima start --profile dev --cpu 4 --memory 8  # Custom resources
```

### Use Profiles with Docker

Each profile creates a Docker context named `colima-<profile>` (default profile is just `colima`):

```bash
docker --context colima ps          # Default/production
docker --context colima-dev ps      # Development
docker --context colima-test ps     # Testing
```

### Portainer with Multiple Profiles

Each Portainer instance only sees its own profile. Use different ports:

```bash
# Production on port 9000
docker --context colima run -d -p 9000:9000 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Dev on port 9001
docker --context colima-dev run -d -p 9001:9001 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest --bind=:9001
```

### Lazydocker with Profiles

```bash
DOCKER_CONTEXT=colima lazydocker        # Production
DOCKER_CONTEXT=colima-dev lazydocker    # Development
DOCKER_CONTEXT=colima-test lazydocker   # Testing
```

## Docker Socket Location

| Profile | Socket |
|---------|--------|
| default | `~/.colima/default/docker.sock` |
| prod | `~/.colima/prod/docker.sock` |

### Default Socket Symlink

To use `docker` commands without specifying `--context`, create a symlink:

```bash
sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
```

The `setup-colima.sh` script creates this symlink automatically.

## Docker Contexts

Docker CLI uses contexts to switch between different Docker daemons.

### Available Contexts

| Context | Endpoint | Description |
|---------|----------|-------------|
| `colima` | `~/.colima/default/docker.sock` | Development (default profile) |
| `colima-prod` | `~/.colima/prod/docker.sock` | Production profile |
| `default` | `/var/run/docker.sock` | Symlink to default profile |

### View Contexts

```bash
docker context ls
```

The active context is marked with `*`.

### Switch Active Context

```bash
docker context use colima        # Use development (default)
docker context use colima-prod   # Use production
```

### Target Specific Context Without Switching

```bash
# Run commands on production
docker --context colima-prod ps
docker --context colima-prod logs <container>

# Run commands on development (default)
docker ps
docker run ...
```

### Recommended Setup

With the symlink in place, `docker` commands use default profile:

```bash
docker ps                        # Uses default (dev)
docker --context colima-prod ps  # Uses production
```

Access production containers via:
- `docker --context colima-prod ...` for CLI
- Portainer at http://localhost:9000 for web UI

## Container Management UI

### Portainer (Web UI)

Portainer provides a web UI to manage containers. Each instance only sees containers in its own profile.

Start Portainer for production:

```bash
docker --context colima-prod run -d -p 9000:9000 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Open http://localhost:9000 and create an admin account on first visit.

**Note:** Portainer runs inside the Colima VM, so it only manages containers in that specific profile.

### Lazydocker (Terminal UI)

Lazydocker uses the active Docker context.

Install:

```bash
brew install lazydocker
```

Run for active context:

```bash
lazydocker
```

Run for specific context:

```bash
lazydocker                             # Development (default)
DOCKER_CONTEXT=colima-prod lazydocker  # Production
```

Key bindings:

| Key | Action |
|-----|--------|
| `↑/↓` | Navigate |
| `Enter` | Select |
| `d` | Delete/remove |
| `s` | Stop container |
| `r` | Restart container |
| `a` | Attach to container |
| `l` | View logs |
| `x` | Open menu |
| `q` | Quit |

## Docker Compose

Use Docker Compose with Colima for multi-container applications.

### Example docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"

  api:
    build: ./api
    depends_on:
      - postgres
    ports:
      - "3000:3000"

volumes:
  pgdata:
```

### Commands

```bash
# Development (uses default symlink)
docker compose up -d
docker compose down
docker compose down -v   # Wipe data

# Production
docker --context colima-prod compose up -d
docker --context colima-prod compose down
docker --context colima-prod compose logs -f
```

### Dev Containers (Ephemeral)

For development containers you wipe constantly:

```bash
# Start dev environment (default context)
docker compose up -d

# Nuke everything when done
docker compose down -v
```

## Troubleshooting

### Check Status

```bash
colima list                    # All profiles
colima status --profile prod   # Specific profile
docker context ls              # Docker contexts
```

### Restart Profiles

```bash
colima stop && colima start                                  # Default (dev)
colima stop --profile prod && colima start --profile prod    # Prod
```

### View Logs

```bash
colima status --extended
```

### Reset a Profile

```bash
# Reset default (dev)
colima delete && colima start

# Reset prod
colima delete --profile prod && colima start --profile prod
```

## Uninstalling Docker Desktop

If you have Docker Desktop installed and want to fully switch to Colima:

### Before Uninstalling

1. Run setup script:
   ```bash
   ./setup-colima.sh
   ```

2. Verify Colima is working:
   ```bash
   colima list
   docker ps
   ```

3. Migrate any important containers/volumes from Docker Desktop

### Uninstall Script

```bash
./uninstall-docker-desktop.sh
```

This script will:
- Quit Docker Desktop if running
- Remove the Docker Desktop application
- Remove all Docker Desktop data, containers, images, and volumes
- Remove Docker Desktop configuration and logs

### After Uninstalling

Create the default socket symlink:

```bash
sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
```

### Manual Uninstall

```bash
# Quit Docker Desktop first, then:
rm -rf /Applications/Docker.app
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Application\ Support/Docker\ Desktop
rm -rf ~/Library/Preferences/com.docker.docker.plist
rm -rf ~/Library/Saved\ Application\ State/com.electron.docker-frontend.savedState
rm -rf ~/Library/Logs/Docker\ Desktop

# Create symlink to default profile
sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
```
