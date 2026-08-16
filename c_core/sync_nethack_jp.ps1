# NetHackJP 本家リポジトリから c_core/nethack_jp へ Git Subtree で更新を取り込むスクリプト
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
param (
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

Write-Host "===> NetHackJP のリモートリポジトリを確認中..." -ForegroundColor Cyan
$remotes = git remote
if ($remotes -notcontains "nethack-jp") {
    Write-Host "リモート 'nethack-jp' を追加します: https://github.com/satokiyon/NetHackJP.git" -ForegroundColor Yellow
    git remote add nethack-jp https://github.com/satokiyon/NetHackJP.git
}

Write-Host "===> NetHackJP の最新コミット情報を取得中 (git fetch nethack-jp)..." -ForegroundColor Cyan
git fetch nethack-jp

Write-Host "===> c_core/nethack_jp に NetHackJP ($Branch ブランチ) の更新をマージ中 (git subtree pull)..." -ForegroundColor Cyan
git subtree pull --prefix=c_core/nethack_jp nethack-jp $Branch --squash

if ($LASTEXITCODE -eq 0) {
    Write-Host "===> 正常に NetHackJP の更新を取り込みました！" -ForegroundColor Green
} else {
    Write-Host "===> マージ中にコンフリクトが発生したか、エラーが発生しました。手動で確認してください。" -ForegroundColor Red
}
