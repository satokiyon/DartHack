# NetHack 本家リポジトリから c_core/nethack_en へ Git Subtree で更新を取り込むスクリプト
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
param (
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

Write-Host "===> NetHack 本家のリモートリポジトリを確認中..." -ForegroundColor Cyan
$remotes = git remote
if ($remotes -notcontains "nethack-en") {
    Write-Host "リモート 'nethack-en' を追加します: https://github.com/NetHack/NetHack.git" -ForegroundColor Yellow
    git remote add nethack-en https://github.com/NetHack/NetHack.git
}

Write-Host "===> NetHack 本家の最新コミット情報を取得中 (git fetch nethack-en)..." -ForegroundColor Cyan
git fetch nethack-en

Write-Host "===> c_core/nethack_en に NetHack ($Branch ブランチ) の更新をマージ中 (git subtree pull)..." -ForegroundColor Cyan
git subtree pull --prefix=c_core/nethack_en nethack-en $Branch --squash

if ($LASTEXITCODE -eq 0) {
    Write-Host "===> 正常に NetHack 本家の更新を取り込みました！" -ForegroundColor Green
} else {
    Write-Host "===> マージ中にコンフリクトが発生したか、エラーが発生しました。手動で確認してください。" -ForegroundColor Red
}
