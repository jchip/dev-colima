# Colima Setup

Colima is a container runtime for macOS that provides Docker compatibility using the macOS Virtualization.Framework.

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

## Dual Docker Environment

This setup uses two separate Docker environments:

| Environment | Purpose | Access |
|-------------|---------|--------|
| Docker Desktop | Development | `docker ...` (default) |
| Colima | Production | `docker --context colima ...` or Portainer |

This separation keeps development experiments isolated from production containers.

Alternatively, you can use multiple Colima profiles and uninstall Docker Desktop entirely (see [Uninstalling Docker Desktop](#uninstalling-docker-desktop)).

## Prerequisites

- macOS
- Homebrew
- Docker Desktop (optional, for development)

## Installation

Run the setup script:

```bash
./setup-colima.sh
```

This script will:
- Install Colima and Docker CLI via Homebrew (if not installed)
- Start Colima if not running
- Verify the installation

## Manual Installation

```bash
brew install colima docker
colima start
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

```
~/.colima/default/docker.sock
```

## Docker Contexts

Docker CLI uses contexts to switch between different Docker daemons.

### Available Contexts

| Context | Endpoint | Description |
|---------|----------|-------------|
| `desktop-linux` | `~/.docker/run/docker.sock` | Docker Desktop |
| `colima` | `~/.colima/default/docker.sock` | Colima |
| `default` | `/var/run/docker.sock` | Symlink to Docker Desktop |

### View Contexts

```bash
docker context ls
```

The active context is marked with `*`.

### Switch Active Context

```bash
docker context use desktop-linux  # Use Docker Desktop (for development)
docker context use colima         # Use Colima (for production)
```

### Target Specific Context Without Switching

```bash
# Run commands on Colima while desktop-linux is active
docker --context colima ps
docker --context colima run ...
docker --context colima logs <container>
docker --context colima exec -it <container> sh

# Run commands on Docker Desktop while colima is active
docker --context desktop-linux ps
```

### Recommended Setup

Keep `desktop-linux` as the active context for daily development:

```bash
docker context use desktop-linux
```

Access Colima containers via:
- `docker --context colima ...` for CLI
- Portainer at http://localhost:9000 for web UI

## Container Management UI

### Portainer (Web UI for Colima)

Portainer provides a web UI to manage Colima containers. It runs inside Colima and only shows Colima containers, regardless of which Docker context is active on the host.

Start Portainer in Colima:

```bash
docker --context colima run -d -p 9000:9000 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Open http://localhost:9000 and create an admin account on first visit.

**Note:** Portainer connects to the Docker socket inside Colima's VM, so it will always manage Colima containers only - even if you switch the CLI context to Docker Desktop.

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
DOCKER_CONTEXT=colima lazydocker        # Colima
DOCKER_CONTEXT=desktop-linux lazydocker  # Docker Desktop
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
# Start services
docker --context colima compose up -d

# Stop services
docker --context colima compose down

# Stop and remove volumes (wipe data)
docker --context colima compose down -v

# View logs
docker --context colima compose logs -f

# Rebuild and restart
docker --context colima compose up -d --build
```

### Dev Containers (Ephemeral)

For development containers you wipe constantly:

```bash
# Start dev environment
docker --context colima-dev compose up -d

# Nuke everything when done
docker --context colima-dev compose down -v
```

## Troubleshooting

### Check Status

```bash
colima status
docker version
```

### Restart Colima

```bash
colima stop
colima start
```

### View Logs

```bash
colima status --extended
```

### Reset Colima

```bash
colima delete
colima start
```

## Uninstalling Docker Desktop

If you want to fully switch to Colima and remove Docker Desktop:

### Before Uninstalling

1. Ensure Colima is working:
   ```bash
   colima status
   docker --context colima ps
   ```

2. Migrate any important containers/volumes from Docker Desktop to Colima

### Uninstall Script

```bash
./uninstall-docker-desktop.sh
```

This script will:
- Quit Docker Desktop if running
- Remove the Docker Desktop application
- Remove all Docker Desktop data, containers, images, and volumes
- Remove Docker Desktop configuration and logs
- Remove the `/var/run/docker.sock` symlink
- Set Colima as the default Docker context

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
sudo rm -f /var/run/docker.sock
docker context use colima
```
