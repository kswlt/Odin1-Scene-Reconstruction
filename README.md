# Odin1-Scene-Reconstruction

Manifold Tech **Odin1** 场景三维重建基础环境：Windows 11 → usbipd-win → WSL2 Ubuntu 22.04 → Docker → ROS2 Humble → 官方 `manifoldsdk/odin_ros_driver`，实现 Odin1 识别、RGB / LiDAR / IMU / SLAM / Odometry Topic 输出、SLAM 建图、地图保存、recorddata（MindCloud 原始数据）采集。

> 状态：**核心链路已全通并真机验证**（见下方"当前验证结果"）。后续三维重建管线（点云 → Mesh → 3DGS → Web/UE/Isaac Sim）以 `data/recorddata`、`data/maps` 为基础。

## 系统架构

```
Windows 11 (Odin1 USB 2207:0019)
   │  usbipd-win 4.4.x (bind --force, TCP 3240)
   ▼
WSL2 Ubuntu 22.04 (systemd)
   │  /dev/bus/usb
   ▼
Docker (WSL 内原生 docker-ce, privileged + host network)
   │  bind mount /dev/bus/usb + /tmp/.X11-unix (WSLg)
   ▼
ROS2 Humble (ros:humble-ros-base-jammy, OpenCV 4.5.4)
   │  odin_ros_driver v0.14.3 (官方 colcon 构建)
   ▼
Odin1 流式输出: RGB / IMU / cloud_raw / cloud_render / cloud_slam / odometry / path / tf
   │  recorddata(.olx) ──→ MindCloud / 3D 重建
   │  save_map(.bin)    ──→ 地图
```

## 当前验证结果（2026-09-09，真机）

| 项目 | 结果 |
|---|---|
| Odin1 USB 进 WSL/容器 | ✅ 2207:0019 manifold hawk |
| 官方 Driver v0.14.3 构建 | ✅ colcon 52s（仅警告） |
| 设备连接 | ✅ "Software connection successful in 6 seconds" |
| 固件（设备实测） | kernel V5.10.209 / mcu V1.5.2 / soc V0.13.1 / daemon V0.6.1 / slam V0.12.1；device-recommended firmware 0.13.0（**无需升级**） |
| calib.yaml | ✅ 从设备获取，备份 `config/odin/calib_N120100104.yaml` |
| SLAM 模式 | ✅ custom_map_mode=1 |
| Topic 频率 | imu 399.7Hz / odometry 10.4Hz / path 10.3Hz / cloud_slam 9.3Hz / cloud_render 5.0Hz / image(1600x1296 bgr8) ~3Hz / cloud_raw ~4.4Hz |
| recorddata | ✅ `data/recorddata/<session>/` 产出 OdinImage.bin、MT*.olx、OdinPose.bin、OdinIMU.bin、calib_online.yaml |
| save_map | ✅ `data/maps/map_*.bin`（示例 490KB，md5 已校验） |

> 说明：image/cloud_raw 频率低于标称（10fps）是 USB2 带宽限制（usbipd vhci 按 USB2 运行）。**建议 Odin1 接 Windows USB3.x 口**后重测；官方注明 SLAM 地图传输建议 USB3.0。

## 第一次安装（新机器复现）

### 0. 前置（Windows）
- Windows 11 + WSL2（`wsl --update`），Ubuntu 22.04（`wsl --install -d Ubuntu-22.04`）
- 安装 usbipd-win：`winget install --exact dorssel.usbipd-win`
- WSL 内 `[boot] systemd=true`（`/etc/wsl.conf`），重启 WSL
- 网络：本仓库环境经 Clash 代理（`172.22.0.1:7890`，WSL NAT 网关）。apt/dockerd/git 均配置走该代理（见 `scripts/linux/setup_apt_proxy.sh`、`install_docker.sh`、`~/.ssh/config`）

### 1. clone + 环境脚本
```bash
cd ~/projects && git clone git@github.com:kswlt/Odin1-Scene-Reconstruction.git
cd Odin1-Scene-Reconstruction
./scripts/linux/setup_udev.sh            # udev 规则 99-odin-usb.rules
./scripts/linux/install_docker.sh        # docker-ce + compose + 代理
```

### 2. 构建镜像
```bash
docker compose build     # 产出 odin-ros2-humble:latest
docker compose up -d     # 常驻容器 odin_ros
```

### 3. 编译官方 Driver
```bash
docker exec odin_ros bash -c 'cd /workspace/src/odin_ros_driver && ./script/build_ros2.sh'
```
官方源克隆自 `https://github.com/manifoldsdk/odin_ros_driver`（tag v0.14.3），位于 `workspace/src/odin_ros_driver`（官方要求必须位于 workspace/src 下）。Driver 读取**包内** `config/control_command.yaml`（忽略 ROS 参数 `config_file`）。

### 4. 插入 Odin1 并转发 USB
```powershell
# 管理员 PowerShell
.\scripts\windows\attach_odin.ps1     # 自动 bind --force + attach + WSL 验证
# 验证
wsl -d Ubuntu -- lsusb                 # 应出现 2207:0019
```

### 5. 启动 Driver
```bash
./scripts/linux/start_odin.sh          # 一键：检查 docker/USB/驱动/话题
# 或手工：
docker exec odin_ros bash -c 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && cd /workspace && nohup ros2 run odin_ros_driver host_sdk_sample > /logs/driver_core.log 2>&1 &'
```

### 6. 可视化（RViz，WSLg 显示到 Windows 桌面）
```bash
docker exec odin_ros bash -c 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && ros2 run rviz2 rviz2 -d /workspace/src/odin_ros_driver/config/odin_ros2.rviz'
```

### 7. 建图 / 记录 / 保存
```bash
./scripts/ros/start_recording.sh   # recorddata=1 + 重启驱动（约 4.5MB/s @USB2）
./scripts/ros/check_topics.sh      # 各话题频率
./scripts/ros/save_map.sh scene_房间名   # 保存地图到 data/maps/scene_*.bin
./scripts/ros/stop_recording.sh    # 停止采集
```

## 数据存放（WSL ext4，勿放 /mnt/c）
| 目录 | 内容 |
|---|---|
| `data/recorddata/` | recorddata 会话（.olx / Odin*.bin / calib_online.yaml），供 MindCloud 等后处理 |
| `data/maps/` | SLAM 地图 .bin（`map_<time>.bin`，save_map.sh 会另存 scene_ 副本） |
| `workspace/src/odin_ros_driver/` | 官方 driver 源码 + config/calib.yaml |
| `logs/` | driver 日志、诊断输出 |
| `config/odin/` | 本项目配置：mapping 配置、calib 备份、原始配置备份 |

Windows 访问 WSL 文件：`\\wsl$\Ubuntu\root\projects\Odin1-Scene-Reconstruction\`（资源管理器地址栏），或 `wsl -d Ubuntu -- cp -r ... /mnt/c/...`。

## 关键经验（本项目踩坑）
1. **compose 传 USB 用卷而不是 `devices:`**：`- /dev/bus/usb:/dev/bus/usb`（devices 不会同步动态节点，容器内 open 失败 LIBUSB_ERROR_NO_DEVICE）。
2. **Driver 忽略 `config_file` 参数**：硬编码读包内 `config/control_command.yaml`（`get_package_source_directory()`），配置需写入该文件（原版备份在 `config/odin/control_command.yaml.original`）。
3. **"missex ok response / Open device failed"**：设备断电重启（官方 FAQ 5.1/5.6）。`scripts/windows/powercycle_odin.ps1` 用 Disable/Enable-PnpDevice 实现等效断电。
4. **usbipd attach 掉线**：WSL VM 空闲关闭会掉 attach —— 保持 WSL 常驻（`wsl -d Ubuntu -- bash -c 'while true; do sleep 120; done'` 或一直开着终端）；nxusbf 过滤器冲突需 `bind --force`。
5. **rviz2 必须在 Dockerfile 里装**（官方 launch 无条件启动 RViz；容器重建会丢手工 apt 安装）。
6. **本机网络必须走代理**：apt/dockerd/git 均配置 172.22.0.1:7890，否则直连超时。

## 文档
- `docs/PROGRESS.md` — 阶段进度与验证记录
- `docs/HANDOFF.md` — 交接状态（当前环境/命令/阻塞项）
- `docs/environment-audit.md` — 环境审计
- `docs/odin-version-compatibility.md` — 固件兼容性

## Troubleshooting（速查）
| 现象 | 处理 |
|---|---|
| usbipd list 无 Odin1 | 换 USB3 口/换线；确认设备供电；`scripts/windows/diagnose_usb.ps1` |
| WSL lsusb 无设备 | 管理员 PowerShell 重跑 `attach_odin.ps1`（自动重试 unbind→bind --force→attach） |
| 容器内无设备 | 确认 compose 用卷挂载 /dev/bus/usb；`docker compose up -d --force-recreate` |
| permission denied (LIBUSB_ERROR_ACCESS) | udev 规则 + 属于 plugdev；`setup_udev.sh` |
| Driver connection failure / missex ok | `powercycle_odin.ps1`（设备断电重启）后重启驱动 |
| firmware mismatch | 见 `docs/odin-version-compatibility.md`；升级需人工确认，禁止自动刷固件 |
| no cloud / no RGB | `check_topics.sh`；确认 sendrgb/senddtof=1；检查 /logs/driver_core.log |
| RViz 无画面 | 确认 WSLg（`echo $DISPLAY`=:0）+ /tmp/.X11-unix 挂载；`xhost +`（容器内若需） |
| recorddata 不生成 | `start_recording.sh`（改 recorddata=1 需重启驱动）；确认 data/recorddata 挂载 |
| save_map 无文件 | SLAM 模式（custom_map_mode=1）；两次 save 间隔≥5s；查看 /data/maps |

## 后续 3D 重建管线（规划）
```
Odin1 → RGB + LiDAR + IMU + Pose + calib
  ├─ recorddata(.olx) → MindCloud → 优化点云 → Mesh
  ├─ RGB + Pose → 3DGS
  └─ SLAM cloud/odom → metric geometry
```
当前已完整保留：RGB、timestamp、point cloud、IMU、odometry、path/pose、calibration、raw recorddata。
