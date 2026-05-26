#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:?IMAGE_NAME is required}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG is required}"
DEPLOY_PORT="${DEPLOY_PORT:-5200}"
DB_NAME="${DB_NAME:-inventory}"
DB_USER="${DB_USER:-app}"
DB_PASSWORD="${DB_PASSWORD:-password123}"

DEPLOY_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
WORK_DIR="/opt/mywebapp"

echo "Image: $DEPLOY_IMAGE"

echo "Pulling new image..."
docker pull "$DEPLOY_IMAGE"

sudo mkdir -p "$WORK_DIR"
sudo tee "$WORK_DIR/.env" > /dev/null <<EOF
APP_IMAGE=${DEPLOY_IMAGE}
APP_PORT=${DEPLOY_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF
sudo chmod 600 "$WORK_DIR/.env"

cd "$WORK_DIR"
docker compose down --remove-orphans || true
docker compose up -d

echo "==> Waiting for containers to start..."
sleep 10

SERVICE_NAME="mywebapp-docker"
UNIT_SOURCE="deploy/mywebapp-docker.service"
UNIT_DEST="/etc/systemd/system/${SERVICE_NAME}.service"

if [ -f "$UNIT_SOURCE" ]; then
  echo "==> Updating systemd unit..."
  sudo cp "$UNIT_SOURCE" "$UNIT_DEST"
  sudo chmod 644 "$UNIT_DEST"
  sudo systemctl daemon-reload
  sudo systemctl enable "${SERVICE_NAME}.service"
  sudo systemctl restart "${SERVICE_NAME}.service"
  sleep 5

  if sudo systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    echo "==> Deploy successful!"
  else
    echo "ERROR: Service failed to start. Logs:" >&2
    sudo journalctl -u "${SERVICE_NAME}.service" --no-pager -n 30
    exit 1
  fi
else
  echo "==> No systemd unit found, skipping service setup."
  docker ps | grep -q "simple-inventory" \
    && echo "==> Deploy successful!" \
    || { echo "ERROR: container not running"; docker ps -a; exit 1; }
fi