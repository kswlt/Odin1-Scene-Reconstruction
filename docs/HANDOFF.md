# HANDOFF — Odin1 Scene Reconstruction 交接文件

> 任何新 Agent：clone 本仓库后先读本文件 + README.md + docs/PROGRESS.md，即可无缝继续。

## 当前真实状态

- **Environment**：Windows 11 Pro Workstation (Build 26200.9168) / WSL2 2.7.12.0 (kernel 6.18.33.2-2) / Ubuntu 22.04.4 LTS (jammy, WSL2, 默认用户 root) / systemd 已启用 / **docker-ce 29.8.0 + Compose v5.5.1**
- **Working features**：
  - WSL 外网正常（apt/curl/dockerd 走 Clash 代理 `http://172.22.0.1:7890`）
  - GitHub SSH：经 Clash 代理认证通过
  - **完整 USB 链路已验证**：Windows usbipd (BUSID 1-9, bind --force) → WSL `lsusb` 可见 `2207:0019 hawk` → **Docker 容器内可见 `2207:0019`**（`--privileged -v /dev/bus/usb:/dev/bus/usb`）
  - udev 规则生效：设备节点 `crw-rw-rw- root plugdev`
  - 防火墙 TCP 3240 放行；项目 Git 仓库已初始化并 push（HEAD: 60e9e22）
- **Broken features / 注意事项**：
  - **WSL VM 空闲自动关闭**（所有 wsl 会话退出后 VM 终止，attach 掉线、dockerd 停止）→ 必须保持常驻会话。当前由后台任务 `wsl -d Ubuntu -- bash -c 'while true; do sleep 120; done'` 保活。用户使用时应打开交互终端。
  - usbipd 的 `nxusbf` 过滤器警告 → 用 `bind --force`（已固化到 attach_odin.ps1）
  - WSL→GitHub 22/443 直连超时（必须经代理）
- **Current blocker**：无
- **Exact commands to continue**：
  ```bash
  # Windows: 确保 WSL 常驻 + USB attach（脚本已自动处理）
  powershell -ExecutionPolicy Bypass -File C:\Users\Admin\Desktop\odin1\scripts\windows\attach_odin.ps1
  # WSL 内
  wsl -d Ubuntu
  cd /root/projects/Odin1-Scene-Reconstruction
  docker compose build    # 构建 ROS2 Humble + Odin 依赖镜像
  ```
- **Latest successful test**：`docker run --privileged -v /dev/bus/usb:/dev/bus/usb ubuntu:22.04` → 设备列表含 `2207:0019`
- **Important paths**：WSL 项目 `/root/projects/Odin1-Scene-Reconstruction`；GitHub `git@github.com:kswlt/Odin1-Scene-Reconstruction.git` (main)；脚本 `scripts/windows/*.ps1`、`scripts/linux/install_docker.sh`、`scripts/linux/setup_apt_proxy.sh`
- **Latest Git commit**：`60e9e22`（feat: add windows usbipd odin workflow）；下一提交：docker engine stage

## 下一步

1. `docker compose build` 构建 ROS2 Humble 镜像（Dockerfile 已就绪：docker/Dockerfile + entrypoint.sh + compose.yaml）
2. Clone 官方 `manifoldsdk/odin_ros_driver`（v0.14.3，需固件 v0.14.0）到 `workspace/src/odin_ros_driver` → colcon 构建
3. 容器内启动 Driver → 验证连接/calib.yaml → ROS Topics → SLAM → recorddata → save_map
