#!/bin/bash
docker exec odin_ros bash -c '
source /opt/ros/humble/setup.bash
source /workspace/install/setup.bash
for t in /odin1/odometry /odin1/path /odin1/cloud_slam /odin1/cloud_render /odin1/imu; do
  echo "=== $t ==="
  timeout 8 ros2 topic hz $t 2>&1 | grep -E "average rate" | head -1
done
echo "=== cloud_slam info ==="
timeout 8 ros2 topic echo /odin1/cloud_slam --once 2>/dev/null | grep -E "frame_id|width:|height:|is_dense" | head -4
'
