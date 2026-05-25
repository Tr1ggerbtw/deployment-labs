#!/bin/bash
set -e

echo "[1/5] Updating system..."
apt-get update -qq || true
apt-get upgrade -y -qq || true

echo "[2/5] Installing Docker and SSH..."
apt-get install -y -qq ca-certificates curl openssh-server

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker admin

echo "[3/5] Enabling SSH password authentication..."
systemctl enable ssh
systemctl start ssh
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

echo "[4/5] Configuring sudo and directories..."
echo "admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin-nopasswd
chmod 0440 /etc/sudoers.d/admin-nopasswd

systemctl stop nginx || true
systemctl disable nginx || true

mkdir -p /opt/mywebapp/nginx
mkdir -p /home/admin/.docker
echo '{"auths":{}}' > /home/admin/.docker/config.json
chown -R admin:admin /opt/mywebapp
chown -R admin:admin /home/admin/.docker

echo "[5/5] Installing systemd unit..."
cat > /etc/systemd/system/mywebapp.service << 'UNIT'
[Unit]
Description=MyWebApp Docker Compose Service
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=admin
Group=admin
WorkingDirectory=/opt/mywebapp

ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable mywebapp

echo ""
echo "Setup complete! Target node is ready."