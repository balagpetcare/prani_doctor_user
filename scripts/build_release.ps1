# Production release build (Android)
#
# Prerequisites:
# - Backend API reachable from device/emulator
# - google-services.json in android/app/ (if ENABLE_PUSH=true)
# - Release keystore configured in android/app/build.gradle.kts
#
# Example:
# flutter build apk --release `
#   --obfuscate --split-debug-info=build/debug-info `
#   --dart-define=API_BASE_URL=https://api.your-domain.com `
#   --dart-define=ENABLE_PUSH=true `
#   --dart-define=LOG_NETWORK=false

param(
  [string]$ApiBaseUrl = "https://api.your-domain.com",
  [ValidateSet("dev", "staging", "production")]
  [string]$AppEnv = "production",
  [switch]$SkipObfuscate
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot ..

$args = @(
  "build", "apk", "--release",
  "--dart-define=APP_ENV=$AppEnv",
  "--dart-define=API_BASE_URL=$ApiBaseUrl",
  "--dart-define=ENABLE_PUSH=true",
  "--dart-define=LOG_NETWORK=false"
)

if (-not $SkipObfuscate) {
  $args += @("--obfuscate", "--split-debug-info=build/debug-info")
}

flutter @args
