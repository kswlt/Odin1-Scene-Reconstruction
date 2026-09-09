# PROGRESS — Odin1 Scene Reconstruction 环境搭建进度

> 本文件由 MainAgent 在每个阶段完成后更新，并随阶段 Commit 一起 Push。
> 时间基准：Asia/Tokyo (UTC+9)

## 阶段日志

| 时间 (JST) | 阶段 | 状态 | 说明 | Commit |
|---|---|---|---|---|
| 2026-09-09 | 项目初始化 | DONE | 目录结构、README、.gitignore、docs 骨架，首次 push 成功 | `e4d653b` |
| 2026-09-09 | 环境审计 | DONE | docs/environment-audit.md；修复 WSL 网络（.wslconfig mirrored→nat，备份保留）；SSH 走 Clash 代理 | `8bd3579` |
| 2026-09-09 | WSL 配置 | DONE | /etc/wsl.conf 追加 `[boot] systemd=true`，systemd 生效；apt 正常 | 60e9e22 |
| 2026-09-09 | usbipd / USB 转发 | DONE | Odin1 bind+attach；**WSL lsusb 可见 2207:0019 hawk**；防火墙 TCP 3240 放行；udev 规则 0666/plugdev | `60e9e22` |
| 2026-09-09 | Docker Engine | DONE | WSL 内原生 docker-ce 29.8.0 + Compose v5.5.1；apt/dockerd 走 Clash 代理；**容器内可见 Odin1 (2207:0019)** | `(待提交)` |
| 2026-09-09 | 故障修复 | DONE | WSL VM 空闲自动关闭导致 attach 掉线 → 常驻会话保活；nxusbf 过滤器冲突 → `bind --force` | `(待提交)` |

## 当前状态摘要

- **总进度**：Docker 环境完成，**USB 链路 Windows→WSL→Docker 全通** ✅
- **环境**：Windows 11 26200 / WSL2 2.7.12 / Ubuntu 22.04.4 / docker-ce 29.8.0 / usbipd 4.4.1 / systemd 已启用
- **Odin1 硬件**：BUSID `1-9`（bind --force），WSL lsusb → `2207:0019 hawk`；容器内设备列表含 `2207:0019`
- **Docker**：原生 docker-ce，daemon 代理已配置（pull 正常）
- **ROS**：未安装（下一步：ROS2 Humble 容器）
- **GitHub**：SSH 经 Clash 代理正常；main 分支

## 验证证据（本阶段）

```text
docker --version → 29.8.0；docker compose version → v5.5.1；docker pull hello-world OK
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb ubuntu:22.04 → 设备列表含 2207:0019
WSL 设备节点: crw-rw-rw- 1 root plugdev 189, 2 /dev/bus/usb/001/003（udev 0666 生效）
```

## 关键经验（写入 README Troubleshooting）

1. **WSL VM 空闲自动关闭**：所有 `wsl -- bash -c` 会话退出后 VM 会终止，usbipd attach 随之掉线、dockerd 停止。保持常驻：`wsl -d Ubuntu -- bash -c 'while true; do sleep 120; done'`（后台）或打开交互终端。
2. **nxusbf 过滤器**：usbipd bind 报 `Unknown USB filter 'nxusbf'`，attach 报 `Device in error state` 时，用 `usbipd bind --force` 重建。
3. **WSL 直连外网受限**：apt/curl/dockerd 均配置走本地 Clash 代理 `http://172.22.0.1:7890`。

## 2026-09-09 Stage: Driver hardware connection + ROS topics LIVE
Status: DONE
- Docker image odin-ros2-humble:latest built (ros:humble-ros-base-jammy, OpenCV 4.5.4 single version)
- Official driver v0.14.3 (commit a592cf2) built via ./script/build_ros2.sh (colcon, 52s, warnings only)
- ROOT CAUSE FIX: compose `devices: /dev/bus/usb` did NOT expose device nodes; switched to bind mount volume `- /dev/bus/usb:/dev/bus/usb` -> container can open /dev/bus/usb/001/00X
- Device power-cycle (Disable/Enable-PnpDevice) per official FAQ 5.1/5.6 resolved "missex ok response" -> software connection successful in 6s
- Device firmware live: kernel V5.10.209, mcu V1.5.2, soc V0.13.1, daemon V0.6.1, slam V0.12.1; driver 0.14.3, device-recommended firmware 0.13.0 (no upgrade needed)
- calib.yaml fetched from device -> /root/.ros/odin_ros_driver + backup config/odin/calib_N120100104.yaml
- SLAM mode active (custom_map_mode=1), stream config RGB=1 IMU=1 ODOM=1 DTOF=1 CLOUD_SLAM=1
- Topic rates (measured): imu 398.9Hz, odometry 10.1Hz, cloud_render 10.8Hz, cloud_raw ~4.4Hz, image ~2.9Hz (USB2-limited via usbipd vhci; full rate needs USB3 port)
- Image: 1600x1296 bgr8; cloud_raw: frame_id=lidar, 49152 pts, fields x/y/z(float32)+intensity
- Git: see next commit

## 2026-09-09 Stage: SLAM config + recorddata + save_map LIVE
Status: DONE
- Project mapping config: config/odin/control_command_mapping.yaml (recorddata=1, showpath=1, custom_map_mode=1, mapping_result_dest_dir=/data/maps); pristine copy saved as control_command.yaml.original
- KEY FINDING: driver IGNORES `config_file` ROS param; hardcodes package source dir config/control_command.yaml (get_package_source_directory). Deploy mapping config to that path (official config mechanism, not source modification)
- recorddata ACTIVE: data/recorddata/20260909_174020/ -> OdinImage.bin, MT*.olx, OdinPose.bin, OdinIMU.bin, calib_online.yaml, image/info.txt, image/cam_in_ex.txt; ~156MB in 35s (USB2-limited; official 10min~9.5GB at USB3)
- save_map VERIFIED: /data/maps/map_20260909_174113.bin (501,982 B, md5 6b49d478ca6be8040fc552d860b4555a, device gen 911ms)
- Topic rates (SLAM mode): imu 399.7Hz, odometry 10.4Hz, path 10.3Hz, cloud_slam 9.3Hz (16034 pts, frame odom), cloud_render 5.0Hz
- compose: nested bind ./data/recorddata -> driver recorddata dir; restart: unless-stopped
- Git: see next commit

## 2026-09-09 Stage: workflow scripts + README + RViz (WSLg)
- Scripts: start_recording/stop_recording/save_map/check_topics (ros), start_odin/status/diagnose (linux), powercycle_odin.ps1 (windows)
- README rewritten as full repro guide (architecture, install, workflows, troubleshooting, 3D pipeline plan)
- docs/odin-version-compatibility.md added (device firmware 0.13.x compatible, no upgrade needed)
- RViz: WSLg mounts added to compose (/tmp/.X11-unix + /mnt/wslg); rviz2 added to Dockerfile (rebuild in progress)
- Git: see next commit

## 2026-09-09 18:35 JST Stage: RViz up + usbipd link degradation note
- RViz2 RUNNING via WSLg (OpenGL 4.5, window on Windows desktop) with image odin-ros2-humble (rviz2 in Dockerfile)
- Observed: after ~1h of session + repeated software power-cycles, usbipd vhci link degrades: device enumerates (Device 004->009), opens fine (lsusb -D OK at 17:25), but vendor control channel hangs at "Hardware connected, starting software connection..." (no version read, no timeout)
- Official remedy: physical unplug/replug (FAQ 5.1/5.7) - requested from user; prefer USB3 port
- Also observed: driver crash (segfault/heap corruption) during SIGTERM shutdown when stop-stream times out - restart via pkill -9 avoids it; zombies accumulate harmlessly until container recreate
- NOTE for future sessions: usbipd attach may drop after ~30-50min idle; keep WSL alive + re-attach; if vendor channel hangs, physical replug

## 2026-09-09 19:00 JST Stage: USB link degradation - root cause chain
- Root cause chain for post-17:45 USB instability:
  1. usbipd attach/cycles over ~2h + repeated PnP power-cycles degrade the Windows USB3 stack
  2. Vendor control transfers (SDK lidar_get_version) hang while standard control (lsusb -D) still works
  3. VirtualBox USB filter drivers nxusbf/nxusbh + VBoxUSBMon internal errors (System event log) interfere with usbipd (bind --force needed from day 1)
  4. USB3 root hub restart wedged usbipd service ("The service is currently not running; a reboot should fix that")
- Actions taken (reversible): VBoxUSBMon stopped (VBoxUSB kept, in use); device bindings retained
- Resolution: Windows reboot required to reset USB stack; after boot auto-recovery: usbipd bindings persist -> attach_odin.ps1 -> container auto-start -> patient_start.sh
- Lesson: avoid repeated PnP power cycles; prefer physical replug; after reboot the stack is clean
