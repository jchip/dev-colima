#!/bin/bash

echo "=== Creating Colima Profiles ==="
echo

# Stop default profile if running
if colima status 2>/dev/null | grep -q "running"; then
    echo "Stopping default profile..."
    colima stop
fi

# Create prod profile
echo "Creating prod profile..."
colima start --profile prod
colima stop --profile prod

# Create dev profile
echo "Creating dev profile..."
colima start --profile dev
colima stop --profile dev

echo
echo "=== Profiles Created ==="
echo

colima list

echo
echo "Docker contexts:"
docker context ls

echo
echo "Usage:"
echo "  colima start --profile prod     # Start production"
echo "  colima start --profile dev      # Start development"
echo "  colima list                     # List all profiles"
echo
echo "  docker --context colima-prod ps # Use production"
echo "  docker --context colima-dev ps  # Use development"
echo
echo "Start both profiles now? (y/N)"
read -r confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    colima start --profile prod
    colima start --profile dev
    echo
    colima list
fi
