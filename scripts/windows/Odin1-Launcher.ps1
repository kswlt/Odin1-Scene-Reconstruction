<# Windows desktop UI for starting the Odin1 ROS pipeline. #>
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$PipelineScript = Join-Path $PSScriptRoot 'Odin1-StartPipeline.ps1'
$StatusFile = Join-Path $ProjectRoot 'logs\odin-start-status.txt'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Start-Hidden([string]$Command) {
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Odin1 场景建图启动器'
$form.Size = New-Object System.Drawing.Size(520, 335)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Odin1 Scene Reconstruction'
$title.Location = New-Object System.Drawing.Point(22, 18)
$title.Size = New-Object System.Drawing.Size(465, 30)
$title.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]14, [System.Drawing.FontStyle]::Bold)

$status = New-Object System.Windows.Forms.Label
$status.Text = '接好 Odin 后，点击一键启动。'
$status.Location = New-Object System.Drawing.Point(22, 58)
$status.Size = New-Object System.Drawing.Size(465, 48)
$status.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]10)

$start = New-Object System.Windows.Forms.Button
$start.Text = '一键启动 + 打开 RViz'
$start.Location = New-Object System.Drawing.Point(22, 125)
$start.Size = New-Object System.Drawing.Size(465, 48)
$start.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]11, [System.Drawing.FontStyle]::Bold)

$reset = New-Object System.Windows.Forms.Button
$reset.Text = '定位飘走时：重置定位'
$reset.Location = New-Object System.Drawing.Point(22, 188)
$reset.Size = New-Object System.Drawing.Size(235, 34)
$reset.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]9)

$close = New-Object System.Windows.Forms.Button
$close.Text = '关闭'
$close.Location = New-Object System.Drawing.Point(267, 188)
$close.Size = New-Object System.Drawing.Size(220, 34)
$close.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]9)

$saveMap = New-Object System.Windows.Forms.Button
$saveMap.Text = '保存当前地图'
$saveMap.Location = New-Object System.Drawing.Point(22, 238)
$saveMap.Size = New-Object System.Drawing.Size(235, 34)
$saveMap.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]9)

$openData = New-Object System.Windows.Forms.Button
$openData.Text = '打开录制数据目录'
$openData.Location = New-Object System.Drawing.Point(267, 238)
$openData.Size = New-Object System.Drawing.Size(220, 34)
$openData.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', [single]9)

$form.Controls.AddRange(@($title, $status, $start, $reset, $close, $saveMap, $openData))

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1500
$timer.Add_Tick({
    if (Test-Path -LiteralPath $StatusFile) {
        $latest = Get-Content -LiteralPath $StatusFile -Raw -ErrorAction SilentlyContinue
        if ($latest) { $status.Text = $latest.Trim() }
    }
})
$timer.Start()

$start.Add_Click({
    [IO.File]::WriteAllText($StatusFile, '正在开始诊断与启动…', (New-Object Text.UTF8Encoding $true))
    $status.Text = '正在开始诊断与启动…'
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PipelineScript`"", '-StatusFile', "`"$StatusFile`""
})
$reset.Add_Click({
    $status.Text = '正在重置定位；请静止 2–3 秒。'
    Start-Hidden 'wsl -d Ubuntu -- bash -lc "docker exec odin_ros bash -lc ''source /opt/ros/humble/setup.bash; source /workspace/install/setup.bash; ros2 service call /odin1/reset_algo odin_ros_driver/srv/ResetAlgo \"{value: 1}\"''"'
})
$saveMap.Add_Click({
    $status.Text = '正在保存当前 SLAM 地图…'
    Start-Hidden 'wsl -d Ubuntu -- bash -lc "cd /root/projects/Odin1-Scene-Reconstruction && bash scripts/ros/save_map.sh scene_manual"'
})
$openData.Add_Click({
    Start-Process explorer.exe '\\wsl.localhost\Ubuntu\root\projects\Odin1-Scene-Reconstruction\data\recorddata'
})
$close.Add_Click({ $form.Close() })
[void]$form.ShowDialog()
