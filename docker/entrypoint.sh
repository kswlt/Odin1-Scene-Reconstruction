#!/bin/bash
# 容器入口：source ROS2 Humble + 工作区（若已构建）
set -e
source /opt/ros/humble/setup.bash
if [ -f /workspace/install/setup.bash ]; then
  source /workspace/install/setup.bash
fi
exec "$@"
