#!/bin/bash
# Route apt through the local Clash proxy (WSL direct outbound is filtered on this machine)
set -e
cat > /etc/apt/apt.conf.d/99proxy <<'EOF'
Acquire::http::Proxy "http://172.22.0.1:7890";
Acquire::https::Proxy "http://172.22.0.1:7890";
EOF
echo "apt proxy configured:"
cat /etc/apt/apt.conf.d/99proxy
echo "===APT-UPDATE-TEST==="
apt-get update >/tmp/apt3.log 2>&1 && echo APT_UPDATE_OK || tail -5 /tmp/apt3.log
