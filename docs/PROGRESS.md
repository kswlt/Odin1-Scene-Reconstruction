# PROGRESS — Odin1 Scene Reconstruction 环境搭建进度

> 本文件由 MainAgent 在每个阶段完成后更新，并随阶段 Commit 一起 Push。
> 时间基准：Asia/Tokyo (UTC+9)

## 阶段日志

| 时间 (JST) | 阶段 | 状态 | 说明 | Commit |
|---|---|---|---|---|
| 2026-09-09 | 项目初始化 | DONE | 目录结构、README、.gitignore、docs 骨架，首次 push 成功 | `e4d653b` |
| 2026-09-09 | 环境审计 | DONE | docs/environment-audit.md；修复 WSL 网络（.wslconfig mirrored→nat，备份保留）；SSH 走 Clash 代理 | `8bd3579` |
| 2026-09-09 | WSL 配置 | DONE | /etc/wsl.conf 追加 `[boot] systemd=true`，systemd 生效；apt 正常 | `(随本次提交)` |
| 2026-09-09 | usbipd / USB 转发 | DONE | Odin1 bind (BUSID 1-9) + attach 成功；**WSL lsusb 可见 2207:0019 hawk**；添加防火墙 TCP 3240 放行规则；udev 规则已写入 | `(随本次提交)` |

## 当前状态摘要

- **总进度**：Odin1 USB 已进入 WSL ✅
- **环境**：Windows 11 26200 / WSL2 2.7.12 / Ubuntu 22.04.4 / usbipd 4.4.1 / systemd 已启用
- **Odin1 硬件**：BUSID `1-9`，VID:PID `2207:0019`，WSL `lsusb` → `Bus 001 Device 002: ID 2207:0019 Fuzhou Rockchip Electronics Company hawk`
- **Docker**：采用 WSL 内原生 docker-ce（下一步安装）
- **ROS**：未安装（计划容器内 ROS2 Humble）
- **GitHub**：SSH 经 Clash 代理正常；main 分支

## 验证证据（本阶段）

```text
usbipd list: 1-9 2207:0019 hawk  Shared
WSL lsusb:  Bus 001 Device 002: ID 2207:0019 Fuzhou Rockchip Electronics Company hawk
/dev/bus/usb: 001/002 存在
/etc/udev/rules.d/99-odin-usb.rules: SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="0019", MODE="0666", GROUP="plugdev"
```
