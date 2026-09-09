#!/bin/bash
# start_recording.sh - Enable Odin recorddata (MindCloud .olx capture) and restart driver
# NOTE: recorddata is a startup config (control_command.yaml); changing it requires a driver restart.
set -e
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$REPO/workspace/src/odin_ros_driver/config/control_command.yaml"

# toggle recorddata to 1
sed -i 's/^  recorddata: .*/  recorddata: 1           # 0: off; 1: on (ENABLED)/' "$CONFIG"
echo "[+] recorddata enabled in $CONFIG"
grep -E "^  recorddata:" "$CONFIG"

echo "[*] Restarting driver..."
"$REPO/scripts/ros/restart_driver.sh"
echo "[+] Recording started. Data lands in: $REPO/data/recorddata/<session>/"
