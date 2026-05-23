# Suggest API and web URLs for local WiFi dev (Windows).
$ErrorActionPreference = "SilentlyContinue"

$candidates = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*" -and
    $_.IPAddress -notlike "169.254.*" -and
    $_.PrefixOrigin -ne "WellKnown"
  } |
  Sort-Object InterfaceMetric

if (-not $candidates) {
  Write-Host "No LAN IPv4 found. Run: ipconfig"
  exit 1
}

$ip = $candidates[0].IPAddress
Write-Host "Suggested .env values:"
Write-Host "API_BASE_URL=http://${ip}:3000"
Write-Host "WEB_BASE_URL=http://${ip}:3001"
Write-Host "Interface: $($candidates[0].InterfaceAlias)"
