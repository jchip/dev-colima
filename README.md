# Colima Setup

Colima is a container runtime for macOS that provides Docker compatibility using the macOS Virtualization.Framework.

## Dual Docker Environment

This setup uses two separate Docker environments:

| Environment | Purpose | Access |
|-------------|---------|--------|
| Docker Desktop | Development | `docker ...` (default) |
| Colima | Production | `docker --context colima ...` or Portainer |

This separation keeps development experiments isolated from production containers.

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
