# Launch DartHack VFX Studio (Developer-only standalone tool)
param (
    [switch]$BuildOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$flutterDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $flutterDir)
$privateBuildDir = Join-Path (Split-Path -Parent $repoRoot) "DartHack_private\build_files"

$overlays = @(
    @{
        Src  = Join-Path $privateBuildDir "sys\flutter\cmake\nethack_core.cmake"
        Dest = Join-Path $flutterDir "cmake\nethack_core.cmake"
    },
    @{
        Src  = Join-Path $privateBuildDir "sys\flutter\windows\CMakeLists.txt"
        Dest = Join-Path $flutterDir "windows\CMakeLists.txt"
    }
)

$injectedFiles = @()
$cmakeDir = Join-Path $flutterDir "cmake"
$cmakeDirExisted = Test-Path $cmakeDir

Push-Location $flutterDir
try {
    foreach ($item in $overlays) {
        if (-not (Test-Path $item.Dest)) {
            if (-not (Test-Path $item.Src)) {
                throw "Required build file not found: $($item.Src). Ensure DartHack_private is placed next to DartHack."
            }
            $destParent = Split-Path -Parent $item.Dest
            if (-not (Test-Path $destParent)) {
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }
            Copy-Item -Path $item.Src -Destination $item.Dest -Force
            $injectedFiles += $item.Dest
            Write-Host "    [+ Injected] $($item.Dest)" -ForegroundColor DarkGray
        }
    }

    if ($BuildOnly) {
        Write-Host "==> Building DartHack VFX Studio (Debug) on Windows..." -ForegroundColor Cyan
        flutter build windows --debug -t tools/vfx_studio/main.dart
    } else {
        Write-Host "==> Starting DartHack VFX Studio on Windows..." -ForegroundColor Cyan
        flutter run -t tools/vfx_studio/main.dart -d windows
    }
} finally {
    foreach ($f in $injectedFiles) {
        if (Test-Path $f) {
            Remove-Item -Path $f -Force -ErrorAction SilentlyContinue
            Write-Host "    [- Removed ] $f" -ForegroundColor DarkGray
        }
    }
    if (-not $cmakeDirExisted -and (Test-Path $cmakeDir)) {
        if (@(Get-ChildItem -Path $cmakeDir -Force).Count -eq 0) {
            Remove-Item -Path $cmakeDir -Force -ErrorAction SilentlyContinue
        }
    }
    Pop-Location
}
