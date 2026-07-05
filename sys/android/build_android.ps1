# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-27.
# NetHackJP Android build automation script
# Automated build script for compiling C libraries in WSL and packaging APK in Windows.

$ErrorActionPreference = "Stop"

# Resolve repo root
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
if (-not (Test-Path "$RepoRoot/sys/android")) {
    $RepoRoot = (Get-Item ".").FullName
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " NetHackJP Android Build Automation Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. WSL (Ubuntu-26.04) compile C libraries
Write-Host "[Step 1/2] Compiling C libraries in WSL (Ubuntu-26.04)..." -ForegroundColor Yellow
$WslRepoPath = (wsl -d Ubuntu-26.04 wslpath ($RepoRoot.Replace('\', '/'))).Trim()
Write-Host "WSL repository path: $WslRepoPath" -ForegroundColor Gray

# Clean and make install in WSL (Run setup.sh and fetch Lua first)
wsl -d Ubuntu-26.04 bash -lc "cd '$WslRepoPath/sys/android' && sh ./setup.sh && cd '$WslRepoPath' && make fetch-lua"
# $abilist = @("arm64-v8a", "armeabi-v7a", "armeabi", "x86_64", "x86")
$abilist = @("arm64-v8a")
foreach($abi in $abilist) {
    wsl -d Ubuntu-26.04 bash -lc "cd '$WslRepoPath' && make clean && make ABI=$abi install"
    if ($LASTEXITCODE -ne 0) {
      Write-Error "WSL compilation failed. Check the errors above."
      exit 1
  }
}

# 2. Windows Gradle packaging
Write-Host "[Step 2/2] Packaging APK with Gradle in Windows..." -ForegroundColor Yellow

# Set ANDROID_HOME environment variable for submodules
$env:ANDROID_HOME = "C:\Users\satok\AppData\Local\Android\Sdk"

Push-Location "$RepoRoot/sys/android"
try {
    # Run gradlew.bat
    & .\gradlew.bat assembleDebug
} finally {
    Pop-Location
}

Write-Host "==================================================" -ForegroundColor Green
Write-Host "Build Successful!" -ForegroundColor Green
Write-Host "APK path: $RepoRoot/sys/android/app/build/outputs/apk/debug/app-debug.apk" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
