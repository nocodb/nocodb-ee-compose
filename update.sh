#!/usr/bin/env bash
#
# NocoDB Enterprise Edition — Update
# Pulls latest images and restarts services
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f docker-compose.yml ]; then
  echo "Error: docker-compose.yml not found. Run ./setup.sh first."
  exit 1
fi

echo "Pulling latest images..."
docker compose pull

echo "Restarting services..."
docker compose up -d

echo "Cleaning up old images..."
docker image prune -f

echo "Done."
