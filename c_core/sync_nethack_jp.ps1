# NetHackJP 本家リポジトリから c_core/nethack_jp へ Git Subtree で更新を取り込むスクリプト
param (
    [string]$Branch = "main"
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
git subtree pull --prefix=c_core/nethack_jp nethack-jp $Branch

if ($LASTEXITCODE -eq 0) {
    Write-Host "===> 正常に NetHackJP の更新を取り込みました！" -ForegroundColor Green

    Write-Host "===> 本家 NetHackJP との重要ファイル（extern.h）の宣言整合性を検証中..." -ForegroundColor Cyan
    try {
        $upstreamExtern = git show "nethack-jp/${Branch}:include/extern.h"
        $localExtern = Get-Content "c_core/nethack_jp/include/extern.h" -Raw

        $externMatches = [regex]::Matches($upstreamExtern, "(?m)^extern\s+[^\n;]+;")
        $missingDeclarations = @()
        foreach ($match in $externMatches) {
            $decl = $match.Value.Trim()
            if ($localExtern -notmatch [regex]::Escape($decl)) {
                $missingDeclarations += $decl
            }
        }

        $missingCount = $missingDeclarations.Count
        if ($missingCount -gt 0) {
            Write-Host "[WARNING] 本家 NetHackJP に存在するが c_core/nethack_jp/include/extern.h に含まれていない extern 宣言が $missingCount 件検出されました！" -ForegroundColor Yellow
            foreach ($m in $missingDeclarations) {
                Write-Host "  - $m" -ForegroundColor Red
            }
            Write-Host "マージコンフリクトの解決時や過去の直接編集により本家の宣言が消去された可能性があります。確認および手動修正を行ってください。" -ForegroundColor Yellow
        } else {
            Write-Host "===> extern.h の宣言チェック完了: 本家からの宣言欠損はありません。" -ForegroundColor Green
        }
    } catch {
        Write-Host "[WARNING] 宣言整合性チェックの実行中にエラーが発生しました: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "===> マージ中にコンフリクトが発生したか、エラーが発生しました。手動で確認してください。" -ForegroundColor Red
}
