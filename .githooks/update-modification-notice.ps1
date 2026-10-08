# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01.
param(
    [string]$Date = (Get-Date -Format 'yyyy-MM-dd')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) {
    throw 'Git repository root could not be resolved.'
}

Set-Location $repoRoot

$noticeBody = "Modified by NetHackJP contributor @satokiyon; latest change date: $Date."
$noticeRegex = 'Modified by NetHackJP contributor @satokiyon; latest change date: \d{4}-\d{2}-\d{2}\.'

$excludePathRegexes = @(
    '^binary/',
    '^vsbinary/',
    '^\.git/',
    '^submodules/'
)

$textExtensions = @(
    '.c', '.h', '.cc', '.cpp', '.cxx', '.hpp', '.hh',
    '.lua', '.md', '.markdown', '.xml', '.vcxproj', '.props', '.targets',
    '.rc', '.yml', '.yaml', '.nmake', '.txt', '.sh', '.ps1', '.py', '.pl'
)

function Get-NoticePrefix {
    param(
        [Parameter(Mandatory = $true)][string]$RelPath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Extension
    )

    switch ($Extension) {
        '.c' { return "/* $noticeBody */" }
        '.h' { return "/* $noticeBody */" }
        '.cc' { return "/* $noticeBody */" }
        '.cpp' { return "/* $noticeBody */" }
        '.cxx' { return "/* $noticeBody */" }
        '.hpp' { return "/* $noticeBody */" }
        '.hh' { return "/* $noticeBody */" }
        '.lua' { return "-- $noticeBody" }
        '.md' { return "<!-- $noticeBody -->" }
        '.markdown' { return "<!-- $noticeBody -->" }
        '.xml' { return "<!-- $noticeBody -->" }
        '.vcxproj' { return "<!-- $noticeBody -->" }
        '.props' { return "<!-- $noticeBody -->" }
        '.targets' { return "<!-- $noticeBody -->" }
        '.rc' { return "// $noticeBody" }
        '.yml' { return "# $noticeBody" }
        '.yaml' { return "# $noticeBody" }
        '.nmake' { return "# $noticeBody" }
        '.sh' { return "# $noticeBody" }
        '.ps1' { return "# $noticeBody" }
        '.py' { return "# $noticeBody" }
        '.pl' { return "# $noticeBody" }
        '.txt' { return "NOTICE: $noticeBody" }
    }

    if (($Extension -eq '') -and ($RelPath -match '^\.githooks/' -or $RelPath -match '^DEVEL/hooksdir/')) {
        return "# $noticeBody"
    }

    $leaf = [System.IO.Path]::GetFileName($RelPath).ToLowerInvariant()
    if ($leaf -eq 'readme' -or $leaf -eq 'license' -or $leaf -eq 'copying') {
        return "NOTICE: $noticeBody"
    }

    return $null
}

function Should-SkipPath {
    param([Parameter(Mandatory = $true)][string]$RelPath)

    $ext = [System.IO.Path]::GetExtension($RelPath).ToLowerInvariant()

    # dat 配下は原則除外だが、Lua は自動更新対象に含める
    if ($RelPath -match '^dat/' -and $ext -ne '.lua') {
        return $true
    }

    foreach ($rx in $excludePathRegexes) {
        if ($RelPath -match $rx) {
            return $true
        }
    }

    if ($ext -eq '.json') {
        return $true
    }

    return $false
}

function Has-BinaryNumstat {
    param([Parameter(Mandatory = $true)][string]$RelPath)

    $numstat = git diff --cached --numstat -- "$RelPath"
    if (-not $numstat) {
        return $false
    }

    $first = $numstat | Select-Object -First 1
    if (-not $first) {
        return $false
    }

    $parts = [regex]::Split($first.Trim(), '\s+')
    if ($parts.Length -lt 2) {
        return $false
    }

    return ($parts[0] -eq '-' -and $parts[1] -eq '-')
}

function Update-Notice {
    param(
        [Parameter(Mandatory = $true)][string]$RelPath,
        [Parameter(Mandatory = $true)][string]$NoticePrefix
    )

    if (-not (Test-Path -LiteralPath $RelPath)) {
        return $false
    }

    $raw = Get-Content -LiteralPath $RelPath -Raw
    $newline = if ($raw -match "`r`n") { "`r`n" } else { "`n" }

    if ($raw -match $noticeRegex) {
        $updated = [regex]::Replace($raw, $noticeRegex, $noticeBody, 1)
        if ($updated -ne $raw) {
            Set-Content -LiteralPath $RelPath -Value $updated -NoNewline
            return $true
        }
        return $false
    }

    $ext = [System.IO.Path]::GetExtension($RelPath).ToLowerInvariant()
    $updated = $raw

    if ($ext -in @('.xml', '.vcxproj', '.props', '.targets')) {
        if ($raw -match '^<\?xml[^\n]*\?>\r?\n?') {
            $m = [regex]::Match($raw, '^<\?xml[^\n]*\?>\r?\n?')
            $head = $m.Value
            $tail = $raw.Substring($head.Length)
            $updated = $head + $NoticePrefix + $newline + $tail
        } else {
            $updated = $NoticePrefix + $newline + $raw
        }
    } else {
        $updated = $NoticePrefix + $newline + $raw
    }

    if ($updated -ne $raw) {
        Set-Content -LiteralPath $RelPath -Value $updated -NoNewline
        return $true
    }

    return $false
}

$rawStaged = git diff --cached --name-only --diff-filter=ACMR -z
if (-not $rawStaged) {
    exit 0
}

$files = ($rawStaged -split "`0") | Where-Object { $_ -and $_.Trim().Length -gt 0 }
$changed = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $rel = $file.Replace('\\', '/')

    if ($rel -eq '.githooks/pre-commit') {
        continue
    }

    if (Should-SkipPath -RelPath $rel) {
        continue
    }

    if (Has-BinaryNumstat -RelPath $rel) {
        continue
    }

    $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
    if ($textExtensions -notcontains $ext) {
        if (($ext -eq '') -and ($rel -match '^\.githooks/' -or $rel -match '^DEVEL/hooksdir/')) {
            # continue processing via Get-NoticePrefix
        } else {
        $leaf = [System.IO.Path]::GetFileName($rel).ToLowerInvariant()
        if ($leaf -ne 'readme' -and $leaf -ne 'license' -and $leaf -ne 'copying') {
            continue
        }
        }
    }

    $prefix = Get-NoticePrefix -RelPath $rel -Extension $ext
    if (-not $prefix) {
        continue
    }

    if (Update-Notice -RelPath $rel -NoticePrefix $prefix) {
        git add -- "$rel" | Out-Null
        $changed.Add($rel)
    }
}

if ($changed.Count -gt 0) {
    Write-Host ("pre-commit: modification notice updated in {0} file(s)." -f $changed.Count)
}

exit 0