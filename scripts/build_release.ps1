# Production release build (Android)
#
# Prerequisites:
# - Backend API reachable from device/emulator
# - google-services.json in android/app/ (if ENABLE_PUSH=true)
# - Release keystore configured in android/key.properties
#
# Example:
# .\scripts\build_release.ps1 -ApiBaseUrl "https://api.your-domain.com" -AppBundle

param(
  [string]$ApiBaseUrl = "https://api.your-domain.com",
  [ValidateSet("dev", "staging", "production")]
  [string]$AppEnv = "production",
  [string]$PrivacyPolicyUrl = "https://pranidoctor.com/privacy",
  [string]$CrashWebhookUrl = "",
  [switch]$SkipObfuscate,
  [switch]$AppBundle,
  [switch]$AllowDebugSigning
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$keyProps = Join-Path "android" "key.properties"
$googleServices = Join-Path "android" "app" "google-services.json"

if (-not $AllowDebugSigning -and -not (Test-Path $keyProps)) {
  throw "Release keystore missing: create android/key.properties or pass -AllowDebugSigning for local QA only."
}

if ($AppEnv -eq "production" -and $ApiBaseUrl -notmatch "^https://") {
  throw "Production builds require HTTPS API_BASE_URL."
}

$args = @(
  "build"
)
if ($AppBundle) {
  $args += "appbundle"
} else {
  $args += "apk"
}
$args += @(
  "--release",
  "--dart-define=APP_ENV=$AppEnv",
  "--dart-define=API_BASE_URL=$ApiBaseUrl",
  "--dart-define=PRIVACY_POLICY_URL=$PrivacyPolicyUrl",
  "--dart-define=ENABLE_PUSH=true",
  "--dart-define=LOG_NETWORK=false"
)

if ($CrashWebhookUrl) {
  $args += @("--dart-define=CRASH_REPORTING_WEBHOOK_URL=$CrashWebhookUrl")
}

if (-not $SkipObfuscate) {
  $args += @("--obfuscate", "--split-debug-info=build/debug-info")
}

if (-not (Test-Path $googleServices)) {
  Write-Warning "google-services.json missing — use ENABLE_PUSH=false or add Firebase config."
  $args = $args | ForEach-Object {
    if ($_ -eq "--dart-define=ENABLE_PUSH=true") {
      "--dart-define=ENABLE_PUSH=false"
    } else { $_ }
  }
}

flutter @args
