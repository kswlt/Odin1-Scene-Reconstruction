# attach_odin.ps1 — 将 Odin1 (VID:PID 2207:0019) 通过 usbipd 转发到 WSL
# 用法: PowerShell 管理员运行 或 普通用户运行（attach 不需要管理员，bind 需要）
# 注意: 不会硬编码 BUSID，每次动态识别（重新插拔后 BUSID 可能变化）
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

Write-Host "=== usbipd list ===" -ForegroundColor Cyan
usbipd list

$busId = Find-OdinBusId
if (-not $busId) {
    Write-Host "[-] 未找到 Odin1 (VID:PID $VID`:$PID)。请确认设备已插入且 usbipd 已安装。" -ForegroundColor Red
    exit 1
}
Write-Host "[+] 找到 Odin1: BUSID = $busId" -ForegroundColor Green

$line = usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" } | Select-Object -First 1
$state = if ($line -match "Shared|Attached") { "shared" } else { "not-shared" }
Write-Host "[i] 当前状态: $state"

if ($state -ne "shared") {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "[-] bind 需要管理员权限。请在管理员 PowerShell 中执行:" -ForegroundColor Yellow
        Write-Host "    usbipd bind --busid $busId" -ForegroundColor Yellow
        Write-Host "    或: 右键 PowerShell → 以管理员身份运行，然后重跑本脚本。" -ForegroundColor Yellow
        exit 2
    }
    Write-Host "[*] bind --busid $busId"
    usbipd bind --busid $busId
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] bind 失败。若提示 nxusbf 过滤器不兼容，请尝试: usbipd bind --force --busid $busId" -ForegroundColor Yellow
    }
}

Write-Host "[*] attach --wsl --busid $busId"
usbipd attach --wsl --busid $busId

Write-Host ""
Write-Host "=== 验证 (WSL 内) ===" -ForegroundColor Cyan
Write-Host "    wsl -d Ubuntu -- lsusb"
Write-Host "    应看到: Bus 001 Device xxx: ID 2207:0019 Fuzhou Rockchip Electronics Company hawk"
Write-Host ""
Write-Host "[+] 完成。若 attach 报防火墙错误，请确认 TCP 3240 已放行:"
Write-Host "    New-NetFirewallRule -DisplayName 'usbipd 3240' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3240" -ForegroundColor Yellow
