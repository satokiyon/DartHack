# NetHack 5.0 / DartHack 戦闘アクション効果音キュレーター 起動スクリプト
# 実行するとローカルWebサーバーが立ち上がり、戦闘効果音(26種)に絞り込んだ画面をブラウザで開きます。

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  ⚔️ DartHack 戦闘アクション効果音キュレーター 起動中..." -ForegroundColor Cyan
Write-Host "  URL: http://localhost:8765/?category=combat" -ForegroundColor Yellow
Write-Host "  全26音 (近接5, 遠隔7, 魔法2, モンスター固有12)" -ForegroundColor Green
Write-Host "  自動正規化: -16.0 LUFS / 80Hzハイパス / 先頭無音トリム" -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Cyan

# ブラウザで戦闘カテゴリを開く
Start-Process "http://localhost:8765/?category=combat"

# Python Webサーバー起動
python server.py