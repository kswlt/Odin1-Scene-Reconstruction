#!/bin/bash
# start_odin.sh - One-shot: check environment, start USB/driver if needed, verify streaming
set -e
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONTAINER="odin_ros"

echo "===== [1/6] Docker ====="
docker info >/dev/null 2>&1 || { echo "[-] docker daemon not running"; exit 1; }
docker ps --filter name="$CONTAINER" --format '{{.Names}} {{.Status}}'

echo "===== [2/6] USB (WSL + container) ====="
lsusb | grep -i 2207 || { echo "[-] Odin1 NOT in WSL. Run scripts/windows/attach_odin.ps1 (admin PowerShell)."; exit 1; }
docker exec "$CONTAINER" bash -c 'lsusb | grep -i 2207 || echo "[-] Odin1 NOT in container"'

echo "===== [3/6] Driver process ====="
if ! docker exec "$CONTAINER" bash -c 'pgrep -x host_sdk_sample >/dev/null'; then
  echo "[*] Driver not running, starting..."
  docker exec "$CONTAINER" bash -c '
    source /opt/ros/humble/setup.bash
    source /workspace/install/setup.bash
    cd /workspace
    nohup ros2 run odin_ros_driver host_sdk_sample > /logs/driver_core.log 2>&1 &
    echo "DRIVER_PID=$!"
  '
  sleep 25
fi
docker exec "$CONTAINER" bash -c 'pgrep -x host_sdk_sample >/dev/null && echo "[+] Driver running" || echo "[-] Driver NOT running (check logs/driver_core.log)"'

echo "===== [4/6] Connection status ====="
grep -E "Device ready and streams activated|Software connection" "$REPO/logs/driver_core.log" | tail -2 || echo "[-] no connection log yet"

echo "===== [5/6] Topics ====="
"$REPO/scripts/ros/check_topics.sh" 2>&1 | head -30 || true

echo "===== [6/6] Data dirs ====="
echo "recorddata: $REPO/data/recorddata/ ($(du -sh "$REPO/data/recorddata" 2>/dev/null | cut -f1))"
echo "maps:       $REPO/data/maps/ ($(du -sh "$REPO/data/maps" 2>/dev/null | cut -f1))"
df -h /root | tail -1
echo "[+] start_odin.sh done"
