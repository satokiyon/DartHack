# check_volumes.ps1
# DartHack 音声アセット音量診断＆自動適正化スクリプト
param(
    [switch]$WarnOnly,
    [switch]$Fix,
    [switch]$Json,
    [string]$Target = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Python 実行パス解決
$pythonExe = "python"
$candidate = "C:\Users\satok\AppData\Local\Python\bin\python.exe"
if (Test-Path $candidate) {
    $pythonExe = $candidate
}

$pyScript = Join-Path $scriptDir "check_volumes.py"

$argsList = @()
if ($WarnOnly) { $argsList += "--warn-only" }
if ($Fix)      { $argsList += "--fix" }
if ($Json)     { $argsList += "--json" }
if ($Target)   { $argsList += "--target", $Target }

& $pythonExe $pyScript @argsList