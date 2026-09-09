# Power-cycle Odin1 via Windows PnP (equivalent to unplug/replug, per official FAQ 5.1/5.6),
# then re-attach to WSL and restart the driver.
$ErrorActionPreference = "Continue"

Write-Host "=== 1. Find Odin1 PnP instance ===" -ForegroundColor Cyan
$dev = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match "VID_2207&PID_0019" } | Select-Object -First 1
if (-not $dev) {
    Write-Host "[-] Odin1 PnP device not found" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Device: $($dev.FriendlyName) / $($dev.InstanceId)" -ForegroundColor Green

Write-Host "=== 2. Release usbipd claim ===" -ForegroundColor Cyan
usbipd detach --busid 1-9 2>&1 | Out-Null
Start-Sleep -Seconds 2
usbipd unbind --busid 1-9 2>&1 | Out-Null
Start-Sleep -Seconds 2

Write-Host "=== 3. Disable device (power cycle) ===" -ForegroundColor Cyan
Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false 2>&1 | Out-Null
Start-Sleep -Seconds 4
Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false 2>&1 | Out-Null
Write-Host "[+] Device re-enabled. Waiting for internal boot (12s)..." -ForegroundColor Green
Start-Sleep -Seconds 12

Write-Host "=== 4. Re-bind and attach ===" -ForegroundColor Cyan
usbipd bind --force --busid 1-9 2>&1 | Out-Null
Start-Sleep -Seconds 2
usbipd attach --wsl --busid 1-9 2>&1 | Out-Null
Start-Sleep -Seconds 8
usbipd list | Select-String "1-9"

Write-Host "=== 5. WSL verify ===" -ForegroundColor Cyan
wsl -d Ubuntu -- lsusb | Select-String "2207"
