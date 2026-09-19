# NetHack 5.0 / DartHack BGM・環境音キュレーター 起動スクリプト
# 実行するとローカルWebサーバーが立ち上がり、BGM・環境音(72種)に絞り込んだ画面をブラウザで開きます。

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  🎵 DartHack BGM・環境音キュレーター 起動中..." -ForegroundColor Cyan
Write-Host "  URL: http://localhost:8765/?category=bgm" -ForegroundColor Yellow
Write-Host "  全72音 (フロアBGM 32, ルームBGM 35, 環境音 5)" -ForegroundColor Green
Write-Host "  外部検索: ダンジョンシンセ・ファンタジーTRPG特化 (9サイト)" -ForegroundColor Magenta
Write-Host "  自動正規化: -18.0 LUFS / ステレオ / 96kbps Opus / ソフト無音処理" -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Cyan

# ブラウザでBGMカテゴリを開く
Start-Process "http://localhost:8765/?category=bgm"

# Python Webサーバー起動
python server.py
