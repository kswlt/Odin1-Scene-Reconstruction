#!/bin/bash
# stop_recording.sh - Disable Odin recorddata and restart driver
set -e
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$REPO/workspace/src/odin_ros_driver/config/control_command.yaml"

sed -i 's/^  recorddata: .*/  recorddata: 0           # 0: off; 1: on/' "$CONFIG"
echo "[+] recorddata disabled"
grep -E "^  recorddata:" "$CONFIG"

echo "[*] Restarting driver..."
"$REPO/scripts/ros/restart_driver.sh"
echo "[+] Recording stopped."
