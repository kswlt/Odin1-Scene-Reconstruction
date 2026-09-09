# Odin1 ROS2 Humble 容器（开发配置）
# 基础：ROS 官方 Humble ros-base (Ubuntu 22.04 jammy)
# 依赖依据官方 manifoldsdk/odin_ros_driver README (v0.14.3, 需要 firmware v0.14.0)
FROM ros:humble-ros-base-jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 本机网络环境：WSL 直连外网受限，apt/curl 走 Windows 侧 Clash 代理（172.22.0.1 = WSL NAT 网关）
# 构建期与运行期都可用；其他网络环境可自行调整
ENV http_proxy=http://172.22.0.1:7890
ENV https_proxy=http://172.22.0.1:7890
RUN printf 'Acquire::http::Proxy "http://172.22.0.1:7890";\nAcquire::https::Proxy "http://172.22.0.1:7890";\n' > /etc/apt/apt.conf.d/99proxy

# --- 系统依赖（官方 README 2.2/2.3） ---
# OpenCV >= 4.2.0：jammy 自带 libopencv-dev 4.5.4，单一版本，符合官方要求
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    pkg-config \
    libgtk2.0-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libyaml-cpp-dev \
    libusb-1.0-0-dev \
    libopencv-dev \
    libssl-dev \
    libeigen3-dev \
    # ROS2 消息/库（依据官方 package_ros2.xml + CMakeLists find_package）
    ros-humble-cv-bridge \
    ros-humble-image-transport \
    ros-humble-tf2-ros \
    ros-humble-tf2-geometry-msgs \
    ros-humble-nav-msgs \
    ros-humble-visualization-msgs \
    ros-humble-geometry-msgs \
    ros-humble-sensor-msgs \
    ros-humble-std-msgs \
    ros-humble-rclcpp \
    ros-humble-message-filters \
    ros-humble-pcl-conversions \
    ros-humble-ament-index-cpp \
    ros-humble-rosidl-default-generators \
    ros-humble-rosidl-default-runtime \
    ros-humble-ros2launch \
    ros-humble-ament-cmake \
    ros-humble-rviz2 \
    # 工具
    usbutils \
    iproute2 \
    net-tools \
    curl \
    vim \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# --- 工作区 ---
RUN mkdir -p /workspace/src /data /logs /config
WORKDIR /workspace

# entrypoint：source ROS + workspace
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
