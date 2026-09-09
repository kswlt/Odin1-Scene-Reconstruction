#!/bin/bash
# diagnose.sh - Collect Odin1 pipeline diagnostics into logs/diagnostic_<timestamp>.txt
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONTAINER="odin_ros"
OUT="$REPO/logs/diagnostic_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p "$REPO/logs"

{
echo "===== Odin1 Diagnostic $(date) ====="
echo "--- WSL ---"
uname -a
cat /etc/os-release | head -3
echo "--- USB (WSL) ---"
lsusb
echo "--- USB (container) ---"
docker exec $CONTAINER bash -c 'lsusb' 2>&1
echo "--- device nodes ---"
docker exec $CONTAINER bash -c 'ls -la /dev/bus/usb/001/' 2>&1
echo "--- Docker ---"
docker version --format '{{.Server.Version}}' 2>&1
docker ps -a --filter name=$CONTAINER --format '{{.Names}} {{.Status}}'
echo "--- Driver process ---"
docker exec $CONTAINER bash -c 'ps -ef | grep -E "host_sdk|/opt/ros/humble/bin/ros2" | grep -v grep' 2>&1 || true
echo "--- Driver log (last 40) ---"
tail -40 "$REPO/logs/driver_core.log" 2>/dev/null || echo "no driver log"
echo "--- ROS topics ---"
docker exec $CONTAINER bash -c 'source /opt/ros/humble/setup.bash; source /workspace/install/setup.bash; timeout 10 ros2 topic list 2>&1 | grep odin1' 2>&1 || true
echo "--- recorddata ---"
du -sh "$REPO/data/recorddata" 2>/dev/null
find "$REPO/data/recorddata" -type f -newer "$REPO/data/recorddata/.gitkeep" 2>/dev/null | tail -5
echo "--- maps ---"
ls -la "$REPO/data/maps" 2>/dev/null
echo "--- disk ---"
df -h /root
echo "--- Odin driver version info ---"
grep -E "ros_driver_version|recommended_firmware_version|soc_version|slam_version|kernel_version" "$REPO/logs/driver_core.log" | tail -5 || true
} > "$OUT" 2>&1

echo "[+] Diagnostics written to: $OUT"
