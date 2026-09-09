# HANDOFF — Odin1 Scene Reconstruction 交接文件

> 任何新 Agent：clone 本仓库后先读本文件 + README.md + docs/PROGRESS.md，即可无缝继续。

## 当前真实状态

- **Environment**：Windows 11 Pro Workstation (Build 26200.9168) / WSL2 2.7.12.0 (kernel 6.18.33.2-microsoft-standard-WSL2) / Ubuntu 22.04.4 LTS (jammy, WSL2, 默认用户 root)
- **Working features**：GitHub SSH 认证通过（key: `~/.ssh/github_kswlt`）；Odin1 已在 Windows 侧被 usbipd 识别（BUSID `1-9`, VID:PID `2207:0019`, device name `hawk`）
- **Broken features**：无（尚未开始）
- **Current blocker**：无
- **Exact commands to continue**：
  ```bash
  # Windows PowerShell（项目在 WSL ext4，非 /mnt/c）
  wsl -d Ubuntu
  cd /root/projects/Odin1-Scene-Reconstruction
  ```
- **Latest successful test**：`ssh -T git@github.com` → "Hi kswlt! You've successfully authenticated"
- **Important paths**：
  - WSL 项目：`/root/projects/Odin1-Scene-Reconstruction`
  - GitHub：`git@github.com:kswlt/Odin1-Scene-Reconstruction.git` (branch `main`)
  - Windows 桌面镜像：`C:\Users\Admin\Desktop\odin1`
- **Latest Git commit**：初始化中（首次 commit 尚未执行）

## 下一步

1. git init + 首次 commit + push
2. 环境审计 → docs/environment-audit.md
3. WSL systemd 开启（/etc/wsl.conf 追加 `[boot] systemd=true`，保留现有内容）
4. usbipd bind/attach Odin1 → WSL lsusb 验证
5. WSL 内原生 Docker Engine（docker-ce）安装
6. ROS2 Humble Dockerfile + 官方 odin_ros_driver 集成
