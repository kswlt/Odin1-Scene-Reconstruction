# HANDOFF — Odin1 Scene Reconstruction 交接文件

> 任何新 Agent：clone 本仓库后先读本文件 + README.md + docs/PROGRESS.md，即可无缝继续。

## 当前真实状态

- **Environment**：Windows 11 Pro Workstation (Build 26200.9168) / WSL2 2.7.12.0 (kernel 6.18.33.2-2) / Ubuntu 22.04.4 LTS (jammy, WSL2, 默认用户 root)
- **Working features**：
  - WSL 外网正常（用户已修复网络；`.wslconfig` 由 mirrored 改为 nat，备份 `C:\Users\Admin\.wslconfig.bak-odin-20260909`）
  - GitHub SSH：WSL `~/.ssh/config` 通过 Clash 代理（`nc -X connect -x 172.22.0.1:7890 %h %p`）访问 GitHub，认证通过
  - Odin1 已在 Windows 侧被 usbipd 识别：BUSID `1-9`，VID:PID `2207:0019`，device `hawk`（**未 bind / 未 attach**）
  - 项目 Git 仓库已初始化并 push：`e4d653b`（origin/main）
- **Broken features**：WSL→GitHub 22/443 直连超时（必须经代理）；WSL 内 `lsusb` 未安装；systemd 未启用
- **Current blocker**：无（下一步：启用 systemd → usbipd bind/attach → docker-ce）
- **Exact commands to continue**：
  ```bash
  wsl -d Ubuntu
  cd /root/projects/Odin1-Scene-Reconstruction
  git pull --rebase origin main   # 若远程有新提交
  ```
- **Latest successful test**：`git push -u origin main` → `e4d653b` pushed
- **Important paths**：
  - WSL 项目：`/root/projects/Odin1-Scene-Reconstruction`
  - GitHub：`git@github.com:kswlt/Odin1-Scene-Reconstruction.git` (branch `main`)
  - Windows SSH key：`C:\Users\Admin\.ssh\github_kswlt`（WSL 内 `/root/.ssh/github_kswlt`）
  - Windows 桌面镜像：`C:\Users\Admin\Desktop\odin1`
- **Latest Git commit**：`e4d653b` chore: initialize odin1 reconstruction workspace（已 push）

## 下一步

1. 启用 systemd：/etc/wsl.conf 追加 `[boot] systemd=true`（保留现有 `[network] generateResolvConf = true`）→ `wsl --shutdown` → 验证 `systemctl is-system-running`
2. usbipd：`usbipd bind --busid 1-9`（管理员已就绪）→ `usbipd attach --wsl --busid 1-9` → WSL `lsusb` 确认 2207:0019
3. 安装 docker-ce（Ubuntu jammy 官方源）→ 验证容器可见 /dev/bus/usb
4. 创建 ROS2 Humble Dockerfile（含 Odin Driver 依赖）→ compose.yaml
5. Clone 官方 `manifoldsdk/odin_ros_driver` 到 `workspace/src/` → 构建
