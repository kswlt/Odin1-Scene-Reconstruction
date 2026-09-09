# 环境审计报告 — Odin1 Scene Reconstruction

> 审计时间：2026-09-09 (Asia/Tokyo) · 执行：MainAgent

## 1. Windows 主机

| 项目 | 值 |
|---|---|
| 系统 | Microsoft Windows 11 专业工作站版 |
| 版本 / Build | 10.0.26200 / 26200.9168 (OSArchitecture: 64 位) |
| WSL | 2.7.12.0 |
| WSL 内核 | 6.18.33.2-2 |
| WSLg | 1.0.73.2 |
| Docker Desktop | 已安装（Client 29.2.0, Compose v5.0.2），**守护进程未运行** |
| usbipd-win | 4.4.1-48 |
| 网络 | WiFi (Realtek 8852CE, 1.7Gbps)；本地代理 Clash (127.0.0.1:7890) |

### 已连接 USB 设备（usbipd list）

```
BUSID  VID:PID   DEVICE                       STATE
1-6    04f2:b7b8 Integrated Camera            Shared
1-9    2207:0019 hawk                         Not shared   ← Odin1
1-10   10c4:ea60 Silicon Labs CP210x (COM6)   Not shared
1-12   048d:c992 USB 输入设备                 Not shared
1-14   0bda:5852 Realtek Bluetooth Adapter    Not shared
```

- **Odin1 已物理插入**：BUSID `1-9`，VID:PID `2207:0019`（官方已知值），设备名 `hawk`。
- usbipd 提示：`Unknown USB filter 'nxusbf'`，后续 bind 如失败需 `bind --force`。

## 2. WSL 发行版（目标环境）

| 项目 | 值 |
|---|---|
| 发行版 | Ubuntu 22.04.4 LTS (jammy) |
| WSL 版本 | 2（目标发行版，`wsl -l -v` 确认 VERSION=2） |
| 内核 | 6.18.33.2-microsoft-standard-WSL2 (x86_64) |
| 默认用户 | root (uid=0)，groups: root, docker(gid 1000 已存在) |
| CPU / 内存 | 24 核 / 10 GiB (Swap 3 GiB) |
| 磁盘 | /dev/sdd 1007G，已用 3.0G，可用 953G |
| lsusb | 未安装（需 usbutils） |
| /dev/bus/usb | 不存在（USB 尚未 attach） |
| systemd | 未启用（PID1 = init(Ubuntu)） |
| ROS | 未安装（/opt/ros 不存在） |
| docker-ce | 未安装（PATH 中的 docker 指向 Docker Desktop CLI） |
| 构建工具 | gcc/g++/make 已有；cmake 未装（将在容器内安装） |
| Python | 3.10.12 |
| Git | 2.34.1 |

### /etc/wsl.conf（用户已配置，保留）
```ini
[network]
generateResolvConf = true
```

## 3. 网络与 GitHub

- WSL 外网：**已修复**（用户操作）。此前问题：`.wslconfig` 中 `networkingMode=mirrored` 启动失败（0x8007054f）导致 WSL 无网络。
- 已变更（备份于 `C:\Users\Admin\.wslconfig.bak-odin-20260909`）：`.wslconfig` 改为 `networkingMode=nat`。
- **WSL→GitHub SSH (22/443) 直连被网络策略阻断**；已配置 WSL `~/.ssh/config` 使用 Clash 代理（`nc -X connect -x 172.22.0.1:7890 %h %p`）转发，`ssh -T git@github.com` 验证通过。
- GitHub SSH Key：`~/.ssh/github_kswlt`（Windows 侧同名 key 复用，已注册到 kswlt 账号）。

## 4. 决策记录

| 决策 | 选择 | 理由 |
|---|---|---|
| Docker 方案 | WSL 内原生 docker-ce | USB 设备 (/dev/bus/usb) passthrough 到容器最可靠；Docker Desktop 守护进程未运行且 WSL integration 未配置 |
| 项目位置 | WSL ext4: `/root/projects/Odin1-Scene-Reconstruction` | 避免 /mnt/c 性能与权限问题；数据采集目录优先 ext4 |
| 不操作 | 不卸载 Docker Desktop、不删除现有发行版 | 尊重现有环境，仅新增 |

## 5. 下一步

1. 启用 systemd（/etc/wsl.conf 追加 `[boot] systemd=true`）
2. usbipd bind + attach Odin1 → WSL lsusb 验证
3. 安装 docker-ce（官方源）
4. ROS2 Humble 容器 + odin_ros_driver
