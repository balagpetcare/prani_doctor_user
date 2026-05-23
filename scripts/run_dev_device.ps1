# Run Flutter on a connected Android device using .env dart-defines.
param(
  [string]$Device = "",
  [switch]$ListDevices
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
  Write-Host "Created .env from .env.example — edit API_BASE_URL to your PC WiFi IP before continuing."
}

$defines = & (Join-Path $PSScriptRoot "load_env.ps1")

if ($ListDevices) {
  flutter devices
  exit 0
}

$args = @("run")
if ($Device -ne "") {
  $args += @("-d", $Device)
}
$args += $defines

Write-Host "flutter $($args -join ' ')"
flutter @args
