#!/bin/bash
set -e
cd /root/projects/Odin1-Scene-Reconstruction

echo "=== CLEAN OLD DRIVER (graceful USB release) ==="
docker exec odin_ros bash -c 'pkill -INT -x host_sdk_sample || true; sleep 5; pkill -TERM -x host_sdk_sample || true; sleep 3; pkill -KILL -x host_sdk_sample || true; pkill -TERM -f "^/usr/bin/python3 /opt/ros/humble/bin/ros2 run odin_ros_driver host_sdk_sample" || true; sleep 2; pgrep -a -x host_sdk_sample || echo CLEAN'
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
