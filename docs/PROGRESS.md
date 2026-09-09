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
