# Odin1-Scene-Reconstruction

Windows 11 + WSL2 Ubuntu 22.04 + usbipd + Docker + ROS2 Humble 驱动 Manifold Tech Odin1（RGB + LiDAR + IMU），实现 SLAM 建图、地图保存、recorddata 原始数据采集，为后续三维重建（点云 → Mesh → 3DGS → Web/UE/Isaac Sim）打基础。

## 系统架构

```
Windows 11
  └─ usbipd-win ── USB 转发
       └─ WSL2 Ubuntu 22.04
            └─ Docker Engine
                 └─ ROS2 Humble (Ubuntu 22.04 container)
                      └─ manifoldsdk/odin_ros_driver
                           └─ Odin1 (VID:PID 2207:0019)
```

## 快速开始

```bash
# 0. Windows（管理员 PowerShell）：绑定并转发 Odin1 USB
usbipd bind --busid <ODIN_BUSID>
usbipd attach --wsl --busid <ODIN_BUSID>

# 1. WSL 中构建并启动
cd ~/projects/Odin1-Scene-Reconstruction
docker compose build
./scripts/linux/start_odin.sh
```

详见 `docs/HANDOFF.md` 与 `docs/PROGRESS.md`。

## 文档索引

- `docs/environment-audit.md` — 环境审计
- `docs/PROGRESS.md` — 阶段进度日志
- `docs/HANDOFF.md` — 交接文件（任何 Agent 从此继续）
- `docs/odin-version-compatibility.md` — Odin Driver / Firmware 兼容性
