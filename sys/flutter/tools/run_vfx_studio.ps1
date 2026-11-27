# Launch DartHack VFX Studio (Developer-only standalone tool)
$ErrorActionPreference = 'Stop'
$flutterDir = Split-Path -Parent $PSScriptRoot
Push-Location $flutterDir
try {
    Write-Host "==> Starting DartHack VFX Studio on Windows..." -ForegroundColor Cyan
    flutter run -t tools/vfx_studio/main.dart -d windows
} finally {
    Pop-Location
}
