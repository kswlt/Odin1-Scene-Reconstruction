#!/bin/bash
# status.sh - Overall Odin1 pipeline status summary
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
CONTAINER="odin_ros"

echo "========== Odin1 Pipeline Status =========="
echo "USB (WSL):    $(lsusb 2>/dev/null | grep -qi 2207 && echo 'Odin1 DETECTED' || echo 'not detected')"
echo "USB (cont):   $(docker exec $CONTAINER bash -c 'lsusb' 2>/dev/null | grep -qi 2207 && echo 'Odin1 DETECTED' || echo 'not detected')"
echo "Docker:       $(docker info >/dev/null 2>&1 && echo running || echo NOT running)"
echo "Container:    $(docker ps --filter name=$CONTAINER --format '{{.Status}}' 2>/dev/null || echo 'not found')"
echo "Driver:       $(docker exec $CONTAINER bash -c 'pgrep -x host_sdk_sample >/dev/null' 2>/dev/null && echo running || echo stopped)"
echo "SLAM mode:    $(grep -E '^  custom_map_mode:' $REPO/workspace/src/odin_ros_driver/config/control_command.yaml | tr -d ' ')"
echo "Recorddata:   $(grep -E '^  recorddata:' $REPO/workspace/src/odin_ros_driver/config/control_command.yaml | tr -d ' ')  dir=$(du -sh $REPO/data/recorddata 2>/dev/null | cut -f1)"
echo "Last map:     $(ls -t $REPO/data/maps/*.bin 2>/dev/null | head -1 | xargs -r basename) ($(ls -lt $REPO/data/maps/*.bin 2>/dev/null | head -1 | awk '{print $5" bytes"}'))"
echo "Disk:         $(df -h /root | tail -1 | awk '{print $4" free"}')"
echo "==========================================="
