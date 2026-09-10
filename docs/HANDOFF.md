# HANDOFF — Odin1 Scene Reconstruction

## Current state (2026-09-09 17:35 JST)
**THE CORE PIPELINE IS LIVE**: Windows -> usbipd -> WSL2 -> Docker -> ROS2 Humble -> odin_ros_driver v0.14.3 -> Odin1 connected, streaming.

## Environment
- Windows 11 Pro Workstation Build 26200.9168; WSL2 2.7.12.0 (kernel 6.18.33.2-2); Ubuntu 22.04.4 (root, systemd on)
- docker-ce 29.8.0 + Compose v5.5.1 in WSL (NOT Docker Desktop daemon); proxy via Clash 172.22.0.1:7890 (apt/dockerd/git)
- Project: /root/projects/Odin1-Scene-Reconstruction (WSL ext4)

## Working
- USB: usbipd 4.4.1, Odin1 2207:0019 (BUSID dynamic, currently 1-9), bind --force needed (nxusbf filter), attach -> WSL -> container (bind mount /dev/bus/usb)
- Docker: image odin-ros2-humble:latest; container odin_ros (compose up -d, privileged+host net, sleep infinity)
- Driver: built OK; connection OK after device power-cycle; SLAM mode=1; all core topics publishing real data
- calib.yaml: fetched, backed up to config/odin/calib_N120100104.yaml

## How to continue (exact commands)
1. Keep WSL VM alive: open a wsl terminal (or background `wsl -d Ubuntu -- bash -c 'while true; do sleep 120; done'`)
2. Attach USB if dropped: PowerShell admin -> scripts/windows/attach_odin.ps1 (auto bind --force + attach)
3. If "missex ok response": scripts/windows/powercycle_odin.ps1 (Disable/Enable-PnpDevice), then restart driver
4. Start driver:
   docker exec odin_ros bash -c 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && cd /workspace && nohup ros2 run odin_ros_driver host_sdk_sample --ros-args -p config_file:=/workspace/src/odin_ros_driver/config/control_command.yaml > /logs/driver_core.log 2>&1 &'
5. Check topics: docker exec odin_ros bash -c 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && ros2 topic list'
6. Driver log: /root/projects/Odin1-Scene-Reconstruction/logs/driver_core.log

## Blockers / next
- None blocking. Next: SLAM verification (move device, check cloud_slam/path), recorddata, save_map, RViz via WSLg, diagnostics, README finalize
- Note: RGB ~2.9Hz / cloud_raw ~4.4Hz due to USB2 vhci bandwidth; try USB3 port on Windows side to improve
- Official launch file needs rviz2 (installed) + X display; headless core run uses `ros2 run host_sdk_sample` directly

## Update 2026-09-09 17:45 JST
- SLAM mode=1 streaming with recorddata ON and path publishing; map saving verified to /data/maps
- Next: RViz via WSLg, diagnostics, README finalize, full workflow scripts (start_odin.sh/status.sh)

## Update 2026-09-09 18:10 JST
- rviz2 added to Dockerfile; image rebuild running (task may take several minutes via proxy)
- After rebuild: docker compose up -d --force-recreate, start driver, then ros2 run rviz2 (WSLg window appears on Windows desktop)
- All workflow scripts in place: scripts/ros/*, scripts/linux/*, scripts/windows/*

## Update 2026-09-09 18:35 JST
- RViz2 verified running via WSLg. All milestones (driver connect, topics, recorddata, save_map) were LIVE-verified earlier in session
- USB vhci link degraded after ~1h (control channel hang). Recovery: user physically replugged Odin1 (USB3 port). After replug: run scripts/windows/attach_odin.ps1 (admin) then scripts/ros/restart_driver.sh (or patient_start.sh)
- If driver hangs at "Hardware connected": powercycle_odin.ps1 -> restart; if still hangs: physical replug

## Update 2026-09-09 19:00 JST
- BLOCKED (host-level, requires Windows reboot): USB3 stack degraded after hub restart; usbipd service crashed ("a reboot should fix that")
- AFTER REBOOT, exact commands (auto-run by agent):
  1. Ensure WSL keep-alive: `wsl -d Ubuntu -- bash -c 'while true; do sleep 120; done'` (background)
  2. `powershell -File scripts/windows/attach_odin.ps1` (bindings persist; script re-binds if needed)
  3. Container auto-starts via compose restart policy; verify `docker exec odin_ros lsusb`
  4. `scripts/ros/patient_start.sh` -> verify hz via final_check.sh
- If VBoxUSBMon restarts on boot: stop again if interference recurs

## Update 2026-09-09 19:30 JST (FINAL)
- Environment: COMPLETE and verified once end-to-end (17:31-17:45: driver connect 6s, all topics, recorddata 156MB, save_map 501KB valid)
- CURRENT BLOCKER: SDK vendor control (lidar_get_version) times out despite device enumerating in Windows/WSL/Docker and standard control working. All software recovery exhausted (see PROGRESS.md). Device is attached (usbipd 1-4 Attached, WSL Device 003)
- Post-reboot reality: usbipd bind is NOT persistent; xHCI controller can come up CM_PROB_DISABLED_SERVICE; USB class UpperFilters may retain nxusbf. Recovery sequence now scripted: reenumerate_odin -> refresh_bind_attach (see scripts/windows/)
- To continue when device vendor control recovers: attach_odin.ps1 -> patient_start.sh -> final_check.sh (all in repo scripts/)
- If device never recovers: test with Windows-native SDK build (libusb on Windows) to isolate device vs usbipd; consider different USB cable/port; contact Manifold support with this log

## Update 2026-09-10 14:00 JST
- Odin1 currently NOT enumerating on Windows (hardware-level USB link, see PROGRESS.md). Environment intact and ready
- When device recovers: attach_odin.ps1 -> patient_start.sh -> verify topics; then consider reducing image fps/resolution in control_command.yaml to mitigate usbipd high-bandwidth stall (connection drops ~90s after stream start)
