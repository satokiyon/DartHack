# NetHack 5.0 / DartHack サウンドキュレーター 起動スクリプト
# 実行するとローカルWebサーバーが立ち上がり、自動的にブラウザでキュレーション画面を開きます。

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  🎮 DartHack サウンドキュレーター 起動中..." -ForegroundColor Cyan
Write-Host "  URL: http://localhost:8765" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan

# ブラウザをバックグラウンドでオープン
Start-Process "http://localhost:8765"

# Python Webサーバー起動
python server.py
