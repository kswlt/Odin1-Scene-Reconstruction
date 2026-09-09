# detach_odin.ps1 — 解除 Odin1 的 usbipd attach（设备回到 Windows）
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

$busId = Find-OdinBusId
if (-not $busId) {
    Write-Host "[-] 未找到 Odin1 (VID:PID $VID`:$PID)。可能已 detach 或未插入。" -ForegroundColor Yellow
    exit 1
}
Write-Host "[+] Odin1 BUSID = $busId"

$line = usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" } | Select-Object -First 1
if ($line -match "Attached") {
    Write-Host "[*] detach --busid $busId"
    usbipd detach --busid $busId
    Write-Host "[+] 已 detach。设备回到 Windows 侧。" -ForegroundColor Green
} else {
    Write-Host "[i] 设备当前未 attach（状态: $line），无需 detach。" -ForegroundColor Yellow
}
