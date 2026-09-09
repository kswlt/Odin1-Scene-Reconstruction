#!/bin/bash
# check_topics.sh - Verify Odin1 ROS topics are publishing real data
set -e
CONTAINER="odin_ros"

docker exec "$CONTAINER" bash -c '
source /opt/ros/humble/setup.bash
source /workspace/install/setup.bash
echo "=== Topic list ==="
timeout 10 ros2 topic list 2>&1 | grep odin1 || true
echo ""
for t in /odin1/imu /odin1/odometry /odin1/path /odin1/image /odin1/cloud_raw /odin1/cloud_render /odin1/cloud_slam; do
  echo "=== $t ==="
  timeout 8 ros2 topic hz "$t" 2>&1 | grep -E "average rate" | head -1
done
'
