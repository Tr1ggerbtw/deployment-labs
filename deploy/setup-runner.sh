#!/bin/bash
set -e

USER="vboxuser"

RUNNER_VERSION="2.333.1"
RUNNER_HASH="18f8f68ed1892854ff2ab1bab4fcaa2f5abeedc98093b6cb13638991725cab74"
RUNNER_DIR="/opt/actions-runner"
REPO_URL="https://github.com/Tr1ggerbtw/deployment-labs"

apt-get update -qq || true
apt-get upgrade -y -qq || true

apt-get install -y -qq \
  curl \
  ca-certificates \
  git \
  jq \
  tar \
  unzip \
  openssh-client

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
usermod -aG docker $USER

mkdir -p "$RUNNER_DIR"
chown $USER:$USER "$RUNNER_DIR"

curl -fsSL \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
  -o /tmp/actions-runner.tar.gz

echo "Validating hash..."
echo "${RUNNER_HASH}  /tmp/actions-runner.tar.gz" | shasum -a 256 -c

tar xzf /tmp/actions-runner.tar.gz -C "$RUNNER_DIR"
chown -R $USER:$USER "$RUNNER_DIR"
rm /tmp/actions-runner.tar.gz

"$RUNNER_DIR/bin/installdependencies.sh"

echo ""
echo "========================================================="
echo " SETUP COMPLETE. Now do the manual registration:"
echo "========================================================="
echo " 1. cd $RUNNER_DIR"
echo " 2. sudo -u $USER ./config.sh \\"
echo "      --url $REPO_URL \\"
echo "      --token YOUR_TOKEN_FROM_GITHUB \\"
echo "      --name my-runner \\"
echo "      --unattended"
echo ""
echo " 3. sudo ./svc.sh install $USER"
echo " 4. sudo ./svc.sh start"
echo "========================================================="