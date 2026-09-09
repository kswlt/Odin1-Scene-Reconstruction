# attach_odin.ps1 — 将 Odin1 (VID:PID 2207:0019) 通过 usbipd 转发到 WSL
# 用法: PowerShell（bind 需要管理员；attach 不需要）
# 注意: 不会硬编码 BUSID，每次动态识别；自动处理 nxusbf 过滤器冲突（bind --force）
$ErrorActionPreference = "Continue"
$VID = "2207"
$PID = "0019"

function Find-OdinBusId {
    $lines = usbipd list 2>$null
    foreach ($line in $lines) {
        if ($line -match "^\s*(\S+)\s+$VID:$PID\b") {
            return $Matches[1]
        }
    }
    return $null
}

function Test-WslRunning {
    $state = wsl -l -v 2>$null | Select-String "Ubuntu"
    return ($state -match "Running")
}

Write-Host "=== 检查 WSL VM 是否运行 ===" -ForegroundColor Cyan
if (-not (Test-WslRunning)) {
    Write-Host "[!] WSL 未运行。正在启动（保持 WSL 窗口/会话常驻，否则 VM 会自动关闭）..." -ForegroundColor Yellow
    wsl -d Ubuntu -- bash -c "echo WSL_READY" | Out-Null
    Start-Sleep -Seconds 5
}

Write-Host "=== usbipd list ===" -ForegroundColor Cyan
usbipd list

$busId = Find-OdinBusId
if (-not $busId) {
    Write-Host "[-] 未找到 Odin1 (VID:PID $VID`:$PID)。请确认设备已插入且 usbipd 已安装。" -ForegroundColor Red
    exit 1
}
Write-Host "[+] 找到 Odin1: BUSID = $busId" -ForegroundColor Green

$line = usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" } | Select-Object -First 1
if ($line -match "Attached") {
    Write-Host "[+] 设备已 Attached，无需重复操作。" -ForegroundColor Green
    Write-Host "    验证: wsl -d Ubuntu -- lsusb"
    exit 0
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[-] bind 需要管理员权限。请在管理员 PowerShell 中执行:" -ForegroundColor Yellow
    Write-Host "    usbipd bind --busid $busId" -ForegroundColor Yellow
    Write-Host "    或: 右键 PowerShell → 以管理员身份运行，然后重跑本脚本。" -ForegroundColor Yellow
    exit 2
}

# bind（未绑定或状态异常时）
if ($line -notmatch "Shared") {
    Write-Host "[*] bind --busid $busId"
    usbipd bind --busid $busId 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] 普通 bind 失败，尝试 bind --force（nxusbf 过滤器冲突）..." -ForegroundColor Yellow
        usbipd bind --force --busid $busId
    }
}

# attach（失败重试一次，必要时 unbind→bind --force→attach）
Write-Host "[*] attach --wsl --busid $busId"
usbipd attach --wsl --busid $busId 2>$null
Start-Sleep -Seconds 6
$stateNow = (usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" } | Select-Object -First 1)
if ($stateNow -notmatch "Attached") {
    Write-Host "[!] 首次 attach 未完成，执行 unbind → bind --force → attach 重试..." -ForegroundColor Yellow
    usbipd unbind --busid $busId 2>$null
    Start-Sleep -Seconds 2
    usbipd bind --force --busid $busId
    Start-Sleep -Seconds 2
    usbipd attach --wsl --busid $busId 2>$null
    Start-Sleep -Seconds 6
}

Write-Host ""
Write-Host "=== 验证 (WSL 内) ===" -ForegroundColor Cyan
usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" }
wsl -d Ubuntu -- lsusb | Select-String "2207"
Write-Host "[+] 完成。WSL 内应看到: ID 2207:0019 Fuzhou Rockchip Electronics Company hawk" -ForegroundColor Green
Write-Host "[i] 提示: 请保持 WSL 常驻（打开 wsl 终端或运行 start_odin.sh），否则 VM 关闭会掉 attach。" -ForegroundColor Yellow
