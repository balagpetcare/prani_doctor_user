# Wireless ADB helper for physical Android devices.
param(
  [string]$DeviceIp = "",
  [int]$Port = 5555,
  [switch]$Disconnect,
  [switch]$ListDevices
)

$ErrorActionPreference = "Stop"

function Require-Adb {
  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if (-not $adb) {
    throw "adb not found. Install Android SDK platform-tools and add to PATH."
  }
}

Require-Adb

if ($ListDevices) {
  adb devices -l
  exit 0
}

if ($Disconnect) {
  adb disconnect
  adb devices -l
  exit 0
}

Write-Host @"
Wireless debugging setup (Android 11+):
1. Phone: Settings → Developer options → Wireless debugging → ON
2. Tap 'Pair device with pairing code'
3. On PC: adb pair <phone-ip>:<pairing-port>  (enter pairing code)
4. Phone: Wireless debugging screen shows IP:port for debugging
5. Run: .\scripts\wireless_debug.ps1 -DeviceIp <debug-ip> -Port <debug-port>
6. Then: .\scripts\run_dev_device.ps1
"@

if ($DeviceIp -eq "") {
  Write-Host "No -DeviceIp provided. Showing current devices only."
  adb devices -l
  exit 0
}

$target = "${DeviceIp}:$Port"
Write-Host "Connecting to $target ..."
adb connect $target
adb devices -l

Write-Host ""
Write-Host "Run app: .\scripts\run_dev_device.ps1"
