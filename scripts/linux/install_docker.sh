#!/bin/bash
# Install docker-ce (native Docker Engine) inside WSL2 Ubuntu 22.04
# Uses local Clash proxy (172.22.0.1:7890) for all network operations
set -e
export DEBIAN_FRONTEND=noninteractive
export http_proxy=http://172.22.0.1:7890
export https_proxy=http://172.22.0.1:7890

echo "=== STEP 1: prerequisites ==="
apt-get install -y ca-certificates curl gnupg >/tmp/docker_install.log 2>&1
install -m 0755 -d /etc/apt/keyrings

echo "=== STEP 2: docker GPG key ==="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "=== STEP 3: apt repo ==="
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

echo "=== STEP 4: apt update + install ==="
apt-get update >>/tmp/docker_install.log 2>&1
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >>/tmp/docker_install.log 2>&1

echo "=== STEP 5: daemon proxy (needed for docker pull) ==="
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<'EOF'
[Service]
Environment="HTTP_PROXY=http://172.22.0.1:7890" "HTTPS_PROXY=http://172.22.0.1:7890" "NO_PROXY=localhost,127.0.0.1,172.22.0.0/20"
EOF

echo "=== STEP 6: enable + start ==="
systemctl daemon-reload
systemctl enable docker >>/tmp/docker_install.log 2>&1
systemctl start docker >>/tmp/docker_install.log 2>&1

echo "=== VERIFY ==="
docker --version
docker compose version
docker info --format 'Server: {{.ServerVersion}}  Driver: {{.Driver}}' 2>&1
docker run --rm hello-world 2>&1 | tail -5
echo "DOCKER_INSTALL_DONE"
