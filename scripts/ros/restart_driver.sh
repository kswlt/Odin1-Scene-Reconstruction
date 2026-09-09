#!/bin/bash
set -e
cd /root/projects/Odin1-Scene-Reconstruction

echo "=== KILL OLD (anchored, no self-match) ==="
docker exec odin_ros bash -c 'pkill -9 -x host_sdk_sample; pkill -9 -f "^/usr/bin/python3 /opt/ros/humble/bin/ros2"; sleep 2; ps -ef | grep -E "host_sdk|/opt/ros/humble/bin/ros2" | grep -v grep || echo CLEAN'
echo "=== START DRIVER ==="
docker exec odin_ros bash -c '
source /opt/ros/humble/setup.bash
source /workspace/install/setup.bash
cd /workspace
nohup ros2 run odin_ros_driver host_sdk_sample > /logs/driver_core.log 2>&1 &
echo "DRIVER_PID=$!"
'
echo "=== WAIT 35s ==="
sleep 35
echo "=== KEY LOG LINES ==="
grep -E "recorddata|showpath|mapping_result|Software connection|Device ready|Stream config|rgb" /root/projects/Odin1-Scene-Reconstruction/logs/driver_core.log | head -15
echo "=== RECORDDATA ==="
find data/recorddata -type f | head -8
du -sh data/recorddata 2>/dev/null
