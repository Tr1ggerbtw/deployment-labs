#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="mywebapp-docker"
UNIT_SOURCE="deploy/mywebapp-docker.service"
UNIT_DEST="/etc/systemd/system/${SERVICE_NAME}.service"
CONTAINER_NAME="simple-inventory"
ENV_FILE="/etc/mywebapp/mywebapp.env"
APP_PORT="${DEPLOY_PORT:-5200}"

echo "Login to GitHub Container Registry..."
echo "${GITHUB_TOKEN:-}" | docker login ghcr.io -u "${GITHUB_ACTOR:-github-actions}" --password-stdin

echo "Pulling new image..."
DEPLOY_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
docker pull "$DEPLOY_IMAGE"

echo "Updating environment file..."
sudo mkdir -p /etc/mywebapp
sudo chmod 750 /etc/mywebapp

cat > /tmp/mywebapp.env <<EOF
DEPLOY_IMAGE=${DEPLOY_IMAGE}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
APP_PORT=${APP_PORT}
CONTAINER_NAME=${CONTAINER_NAME}
EOF

sudo mv /tmp/mywebapp.env "$ENV_FILE"
sudo chmod 600 "$ENV_FILE"

echo "Updating systemd unit..."
sudo cp "$UNIT_SOURCE" "$UNIT_DEST"
sudo chmod 644 "$UNIT_DEST"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}.service"

echo "Restarting service..."
sudo systemctl restart "${SERVICE_NAME}.service"
sleep 5

if sudo systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    echo "Deploy successful!"
else
    echo "ERROR: Service failed to start. Check logs:" >&2
    sudo journalctl -u "${SERVICE_NAME}.service" --no-pager -n 20
    exit 1
fi