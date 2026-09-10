# Attach Odin1 (VID:PID 2207:0019) to WSL through usbipd.
$ErrorActionPreference = 'Stop'
$Vid = '2207'
$ProductId = '0019'
function Find-OdinBusId {
    foreach ($line in (usbipd list)) {
        if ($line -match "^\s*(\S+)\s+${Vid}:${ProductId}\s") { return $Matches[1] }
    }
    return $null
}
$busId = Find-OdinBusId
if (-not $busId) { Write-Error 'Odin1 (2207:0019) is not enumerated by Windows.'; exit 1 }
$line = usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" } | Select-Object -First 1
if ($line -match 'Attached') { wsl -d Ubuntu -- lsusb | Select-String '2207:0019'; exit 0 }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Error 'Run from an elevated PowerShell because usbipd bind requires Administrator.'; exit 2 }
usbipd bind --force --busid $busId
usbipd attach --wsl --busid $busId
Start-Sleep -Seconds 5
$state = usbipd list | Where-Object { $_ -match "^\s*$([regex]::Escape($busId))\s" } | Select-Object -First 1
if ($state -notmatch 'Attached') { throw "usbipd attach did not complete for $busId" }
wsl -d Ubuntu -- lsusb | Select-String '2207:0019'
