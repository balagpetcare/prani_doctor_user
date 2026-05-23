# Reads .env and returns flutter --dart-define arguments.

param(

  [string]$EnvFile = (Join-Path $PSScriptRoot ".." ".env")

)



$ErrorActionPreference = "Stop"

$defines = @()



if (-not (Test-Path $EnvFile)) {

  Write-Warning ".env not found at $EnvFile — copy .env.example to .env and set API_BASE_URL"

  return $defines

}



Get-Content $EnvFile | ForEach-Object {

  $line = $_.Trim()

  if ($line -eq "" -or $line.StartsWith("#")) { return }



  $eq = $line.IndexOf("=")

  if ($eq -lt 1) { return }



  $key = $line.Substring(0, $eq).Trim()

  $value = $line.Substring($eq + 1).Trim()

  if ($value.StartsWith('"') -and $value.EndsWith('"')) {

    $value = $value.Substring(1, $value.Length - 2)

  }



  switch ($key) {

    "APP_ENV" { $defines += "--dart-define=APP_ENV=$value" }

    "API_BASE_URL" { $defines += "--dart-define=API_BASE_URL=$value" }
    "UPLOAD_URL" { $defines += "--dart-define=UPLOAD_URL=$value" }

    "DEV_WIFI_HOST" { $defines += "--dart-define=DEV_WIFI_HOST=$value" }

    "API_HOST" { $defines += "--dart-define=API_HOST=$value" }

    "API_PORT" { $defines += "--dart-define=API_PORT=$value" }

    "WEB_BASE_URL" { $defines += "--dart-define=WEB_BASE_URL=$value" }

    "WEB_PORT" { $defines += "--dart-define=WEB_PORT=$value" }

    "API_CONNECT_TIMEOUT_SEC" { $defines += "--dart-define=API_CONNECT_TIMEOUT_SEC=$value" }

    "API_RECEIVE_TIMEOUT_SEC" { $defines += "--dart-define=API_RECEIVE_TIMEOUT_SEC=$value" }

    "LOG_NETWORK" { $defines += "--dart-define=LOG_NETWORK=$value" }

    "ENABLE_PUSH" { $defines += "--dart-define=ENABLE_PUSH=$value" }

    "PRIVACY_POLICY_URL" { $defines += "--dart-define=PRIVACY_POLICY_URL=$value" }

    "MINIMUM_APP_VERSION" { $defines += "--dart-define=MINIMUM_APP_VERSION=$value" }

    "UPDATE_URL" { $defines += "--dart-define=UPDATE_URL=$value" }

  }

}



return ,$defines

