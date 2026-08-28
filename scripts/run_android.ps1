# Nestly — launch Android emulator and run the app
# Usage:  powershell -ExecutionPolicy Bypass -File scripts\run_android.ps1

$ErrorActionPreference = "Stop"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$sdk\platform-tools;$sdk\emulator;$sdk\cmdline-tools\latest\bin;$env:Path"

$avd = "Nestly_Phone"
$apiUrl = "http://10.0.2.2:4000"  # host machine from Android emulator

Write-Host "Checking AVD..." -ForegroundColor Cyan
$avds = & emulator -list-avds 2>$null
if (-not ($avds -contains $avd)) {
  Write-Host "AVD '$avd' not found. Create it first (see SETUP.md)." -ForegroundColor Red
  exit 1
}

$devices = & adb devices 2>$null | Out-String
if ($devices -notmatch "emulator-\d+\s+device") {
  Write-Host "Starting emulator $avd ..." -ForegroundColor Cyan
  Start-Process -FilePath "$sdk\emulator\emulator.exe" -ArgumentList "-avd", $avd, "-netdelay", "none", "-netspeed", "full"
  $ready = $false
  for ($i = 1; $i -le 36; $i++) {
    Start-Sleep -Seconds 5
    $d = & adb devices 2>$null | Out-String
    if ($d -match "emulator-\d+\s+device") {
      $ready = $true
      break
    }
    Write-Host "  waiting for emulator... ($i)"
  }
  if (-not $ready) {
    Write-Host "Emulator did not become ready. Open Android Studio Device Manager and start Nestly_Phone manually." -ForegroundColor Red
    exit 1
  }
}

Write-Host "Emulator ready. Starting Nestly..." -ForegroundColor Green
Write-Host "API_BASE_URL=$apiUrl (backend must be running on host port 4000)" -ForegroundColor Yellow
Set-Location (Join-Path $PSScriptRoot "..")
flutter run -d emulator-5554 --dart-define=API_BASE_URL=$apiUrl
