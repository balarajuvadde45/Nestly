param(
  [ValidateSet("android", "web", "ios")][string]$Target = "web",
  [string]$Config = "config/release.json"
)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
  if (-not (Test-Path -LiteralPath $Config)) { throw "Provide $Config using config/release.example.json." }
  $releaseConfig = Get-Content -Raw -LiteralPath $Config | ConvertFrom-Json
  foreach ($name in @("API_BASE_URL", "PUBLIC_WEB_URL", "PRIVACY_URL", "TERMS_URL", "SUPPORT_URL")) {
    $value = [string]$releaseConfig.$name
    $parsedUri = $null
    if (-not [Uri]::TryCreate($value, [UriKind]::Absolute, [ref]$parsedUri) -or
        $parsedUri.Scheme -ne "https" -or $parsedUri.IsLoopback -or
        $parsedUri.Host -match "(^|\.)(example\.com|invalid|test)$" -or
        $parsedUri.UserInfo.Length -gt 0) {
      throw "$name must be a real HTTPS URL without credentials."
    }
  }
  if ($Target -eq "android" -and -not (Test-Path -LiteralPath "android/key.properties")) {
    throw "Android releases require android/key.properties and the upload keystore."
  }
  if ($Target -eq "ios" -and -not $IsMacOS) { throw "iOS release builds require macOS and Xcode." }
  & flutter pub get
  if ($LASTEXITCODE -ne 0) { throw "Dependency resolution failed" }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "Flutter analysis failed" }
  & flutter test
  if ($LASTEXITCODE -ne 0) { throw "Flutter tests failed" }
  $buildTarget = switch ($Target) { "android" { "appbundle" } "ios" { "ipa" } default { "web" } }
  & flutter build $buildTarget --release "--dart-define-from-file=$Config"
  if ($LASTEXITCODE -ne 0) { throw "Release build failed" }
} finally { Pop-Location }
