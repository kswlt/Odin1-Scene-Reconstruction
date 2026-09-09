# diagnose_usb.ps1 — 诊断 Odin1 USB 链路（Windows 侧 + WSL 侧）
$ErrorActionPreference = "Continue"
Write-Host "===== Odin1 USB 诊断 (Windows 侧) =====" -ForegroundColor Cyan

Write-Host "--- usbipd 版本 ---"
usbipd --version

Write-Host "--- usbipd list ---"
usbipd list

Write-Host "--- Odin1 识别 (2207:0019) ---"
$found = usbipd list | Select-String "2207:0019"
if ($found) { Write-Host "[+] 找到 Odin1:" -ForegroundColor Green; $found } else { Write-Host "[-] usbipd 未识别 Odin1" -ForegroundColor Red }

Write-Host "--- 防火墙 TCP 3240 规则 ---"
$rule = Get-NetFirewallRule -DisplayName "*3240*" -ErrorAction SilentlyContinue
if ($rule) { $rule | Select-Object DisplayName,Enabled,Direction,Action } else { Write-Host "[-] 未找到 3240 放行规则；如 attach 报防火墙错误需添加:" -ForegroundColor Yellow; Write-Host "    New-NetFirewallRule -DisplayName 'usbipd 3240' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3240" -ForegroundColor Yellow }

Write-Host "--- WSL 内 USB 设备 (lsusb) ---"
wsl -d Ubuntu -- lsusb 2>&1
$wslOdin = wsl -d Ubuntu -- lsusb 2>&1 | Select-String "2207:0019"
if ($wslOdin) { Write-Host "[+] Odin1 已进入 WSL!" -ForegroundColor Green } else { Write-Host "[-] WSL 内未看到 Odin1。检查: 设备是否 bind/attach、TCP 3240、USB 线/端口 (优先 USB3.x)。" -ForegroundColor Yellow }

Write-Host "--- WSL 内设备节点 ---"
wsl -d Ubuntu -- ls -la /dev/bus/usb 2>&1

Write-Host "--- udev 规则 ---"
wsl -d Ubuntu -- cat /etc/udev/rules.d/99-odin-usb.rules 2>&1

Write-Host "===== 诊断完成 =====" -ForegroundColor Cyan
