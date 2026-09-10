<# Backend for Odin1-Launcher.ps1. It verifies a real stream before opening RViz. #>
param([Parameter(Mandatory = $true)][string]$StatusFile)
$ErrorActionPreference = 'Continue'
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$AttachScript = Join-Path $PSScriptRoot 'attach_odin.ps1'
function Set-StartStatus([string]$Message) {
    [IO.File]::WriteAllText($StatusFile, $Message, (New-Object Text.UTF8Encoding $true))
}

Set-StartStatus '1/4 正在连接 Odin 到 WSL…'
& $AttachScript
if ($LASTEXITCODE -ne 0) {
    Set-StartStatus '失败：Windows 没有发现 Odin (2207:0019)，无法启动驱动。'
    exit 1
}

Set-StartStatus '2/4 正在重启 ROS 驱动并等待设备握手…'
$linux = @'
cd /root/projects/Odin1-Scene-Reconstruction
if ! lsusb | grep -q '2207:0019'; then echo USB_NOT_VISIBLE; exit 20; fi
docker restart -t 10 odin_ros >/dev/null || exit 30
sleep 3
: > logs/driver_core.log
: > logs/map_preview.log
docker exec -d odin_ros bash -lc 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && exec ros2 run odin_ros_driver host_sdk_sample > /logs/driver_core.log 2>&1'
docker exec -d odin_ros bash -lc 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && exec ros2 run map_preview map_preview > /logs/map_preview.log 2>&1'
sleep 12
if ! grep -q 'Device ready and streams activated' logs/driver_core.log || grep -q 'Start stream failed\|LIBUSB_TRANSFER_ERROR\|LIBUSB_ERROR_NO_DEVICE' logs/driver_core.log; then
  if grep -q 'LIBUSB_TRANSFER_ERROR\|LIBUSB_ERROR_NOT_FOUND' logs/driver_core.log; then echo USB_STREAM_INTERRUPTED; else echo DRIVER_CONNECTION_TIMEOUT; fi
  exit 21
fi
docker exec odin_ros bash -lc 'pkill -f "/opt/ros/humble/lib/rviz2/rviz2" || true'
sleep 2
docker exec -d odin_ros bash -lc 'source /opt/ros/humble/setup.bash && source /workspace/install/setup.bash && export DISPLAY=:0 && export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir && exec ros2 run rviz2 rviz2 -d /workspace/src/odin_ros_driver/config/odin_ros2.rviz > /logs/rviz.log 2>&1'
echo READY
'@
$result = (& wsl.exe -d Ubuntu -- bash -lc $linux 2>&1 | Out-String)
if ($result -match 'READY') { Set-StartStatus '已启动：LiDAR/SLAM 点云、TF 和一个 RViz 已确认。RGB 暂时关闭以绕过设备控制超时。'; exit 0 }
if ($result -match 'USB_NOT_VISIBLE') { Set-StartStatus '失败：Odin 没有出现在 WSL 的 USB 列表中。'; exit 20 }
if ($result -match 'USB_STREAM_INTERRUPTED') { Set-StartStatus '失败：驱动已连上但 USB 数据流中断；不是 RViz 问题。'; exit 21 }
Set-StartStatus '失败：驱动未开始数据流。请查看 USB 流中断或控制命令超时。'
exit 22
