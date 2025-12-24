#!/bin/bash

set -e

echo "=== Docker Desktop Uninstaller ==="
echo
echo "WARNING: This will permanently delete:"
echo "  - Docker Desktop application"
echo "  - All Docker Desktop containers, images, and volumes"
echo "  - Docker Desktop configuration"
echo
echo "Make sure Colima is working before proceeding:"
echo "  docker --context colima ps"
echo

read -p "Are you sure you want to uninstall Docker Desktop? (y/N) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo
echo "Checking if Docker Desktop is running..."
if pgrep -x "Docker" > /dev/null; then
    echo "Docker Desktop is running. Quitting..."
    osascript -e 'quit app "Docker"' 2>/dev/null || true
    sleep 3
fi

echo "Removing Docker Desktop application..."
rm -rf /Applications/Docker.app

echo "Removing Docker data and containers..."
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker

echo "Removing Docker Desktop support files..."
rm -rf ~/Library/Application\ Support/Docker\ Desktop

echo "Removing Docker preferences..."
rm -rf ~/Library/Preferences/com.docker.docker.plist
rm -rf ~/Library/Saved\ Application\ State/com.electron.docker-frontend.savedState

echo "Removing Docker logs..."
rm -rf ~/Library/Logs/Docker\ Desktop

echo "Removing Docker CLI config (keeping credentials)..."
rm -rf ~/.docker/contexts
rm -rf ~/.docker/features.json
rm -rf ~/.docker/application-template
rm -rf ~/.docker/mutagen
# Keep ~/.docker/config.json for registry credentials

echo "Removing socket symlink..."
sudo rm -f /var/run/docker.sock

echo "Removing Docker contexts..."
docker context rm desktop-linux 2>/dev/null || true
docker context rm default 2>/dev/null || true

echo "Setting Colima as default context..."
docker context use colima 2>/dev/null || true

echo
echo "=== Uninstall Complete ==="
echo
echo "Docker Desktop has been removed."
echo "Colima is now your Docker runtime."
echo
echo "Verify with:"
echo "  docker context ls"
echo "  docker ps"
