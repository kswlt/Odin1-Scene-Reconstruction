# HANDOFF — Odin1 Scene Reconstruction 交接文件

> 任何新 Agent：clone 本仓库后先读本文件 + README.md + docs/PROGRESS.md，即可无缝继续。

## 当前真实状态

- **Environment**：Windows 11 Pro Workstation (Build 26200.9168) / WSL2 2.7.12.0 (kernel 6.18.33.2-2) / Ubuntu 22.04.4 LTS (jammy, WSL2, 默认用户 root) / systemd 已启用
- **Working features**：
  - WSL 外网正常；`/etc/wsl.conf` = `[network] generateResolvConf=true` + `[boot] systemd=true`
  - GitHub SSH：经 Clash 代理（`nc -X connect -x 172.22.0.1:7890 %h %p`）认证通过
  - **Odin1 USB 已进入 WSL**：usbipd bind+attach 成功（BUSID 1-9），WSL `lsusb` 可见 `2207:0019 hawk`
  - Windows 防火墙已放行 TCP 3240（规则名 `usbipd-win 3240 (Odin1 WSL USB)`）
  - udev 规则 `/etc/udev/rules.d/99-odin-usb.rules` 已写入（0666/plugdev）
- **Broken features**：WSL→GitHub 22/443 直连超时（必须经代理）；usbipd 有 `nxusbf` 过滤器警告（bind 已成功，未影响）
- **Current blocker**：无
- **Exact commands to continue**：
  ```bash
  wsl -d Ubuntu
  cd /root/projects/Odin1-Scene-Reconstruction
  git pull --rebase origin main
  # 若 USB 掉了，Windows 侧重新 attach：
  #   usbipd bind --busid 1-9 ; usbipd attach --wsl --busid 1-9
  ```
- **Latest successful test**：`wsl lsusb` → `ID 2207:0019 Fuzhou Rockchip Electronics Company hawk`
- **Important paths**：
  - WSL 项目：`/root/projects/Odin1-Scene-Reconstruction`
  - GitHub：`git@github.com:kswlt/Odin1-Scene-Reconstruction.git` (branch `main`)
  - 脚本：`scripts/windows/attach_odin.ps1` / `detach_odin.ps1` / `diagnose_usb.ps1`；udev: `scripts/linux/setup_udev.sh` + `config/odin/99-odin-usb.rules`
- **Latest Git commit**：`8bd3579` docs: add initial environment audit（下一提交：usbipd workflow）

## 下一步

1. 安装 docker-ce（Ubuntu jammy 官方源）→ 启动 dockerd(systemd) → 验证容器可见 /dev/bus/usb + lsusb
2. 创建 ROS2 Humble Dockerfile（含 Odin Driver 依赖）+ compose.yaml
3. Clone 官方 `manifoldsdk/odin_ros_driver` 到 `workspace/src/` → 构建 → 启动验证
