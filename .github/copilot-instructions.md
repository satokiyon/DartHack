<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-21. -->
# Copilot Instructions for NetHackJP (Technical & Operational)

このファイルは、NetHackJP プロジェクトにおける技術的な運用、ビルド手順、および開発フローに関する指示をまとめたものです。翻訳に関する具体的なガイドラインは `docs/translation-instructions-ja.md` を参照してください。

## 1. プロジェクト構成と環境

- **OS**: Windows (win32)
- **シェル**: PowerShell / VS Developer Shell 推奨
- **ツール**:
  - 文字列検索: `ag` コマンドを使用（`grep` は避ける）
  - スクリプト: `PowerShell` または `Python` を使用（`bash` は避ける）

## 2. ビルド手順 (Windows / VS)

### 推奨: VS Developer Shell 経由
```powershell
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsInstallPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
Import-Module (Join-Path $vsInstallPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
Enter-VsDevShell -VsInstallPath $vsInstallPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
Set-Location (Resolve-Path '.')
msbuild sys\windows\vs\NetHack.sln '/t:NetHack;NetHackW' /p:Configuration=Debug /p:Platform=x64 /m /nologo /verbosity:minimal
```

### 最低確認事項
- Exit Code が `0` であること。
- `binary\Debug\x64\NetHack.exe` と `NetHackW.exe` が生成されること。
- `NetHackW.exe` 起動中はリンク失敗（LNK1168）するため、ビルド前に終了させること。

## 3. アップストリーム同期 (Git)

本家（https://github.com/NetHack/NetHack）の更新は `upstream-base` ブランチを経由して取り込む。

### 同期の手順
```powershell
git switch upstream-base
git pull upstream NetHack-5.0
git switch main
git merge upstream-base
# コンフリクト解決後
git add <解決したファイル>
git commit -m "Merge branch 'upstream-base' into main"
```

## 4. プロジェクト管理とコミット

- **進捗管理**: 計画と進捗を `/memories/repo/translation-notes.md` に記録する。
- **コミットルール**:
  - ユーザーの明示的な依頼がある時のみ行う。
  - `git status --short` で関係ない変更が含まれていないか確認する。
  - コミットメッセージは日本語で簡潔に記述する。
- **デバッグ実装**: 調査用のトレース出力やデバッグフラグは、完了後に必ず削除し、本番コードに残さない。

## 5. 技術的注意点 (Unicode / Console)

- **sys/windows/consoletty.c**:
  - `ReadConsole` は常に `ReadConsoleW` を使い、バッファは `WCHAR` とする。
  - `INPUT_RECORD` の参照には `UnicodeChar` を使う。`AsciiChar` は日本語文字で誤動作の原因となる。

## 6. 技術的注意点 (Object 名ローカライズ: Method C)

- **基本方針**: `include/objects.h` は upstream 英語を維持し、内部ID解決（Lua `des.object({ id = "..." })`、wish、各種検索）を壊さない。
- **表示の日本語化**: 日本語名・未識別外観は `src/obj_jp.c` に分離し、`jp_item_name()` / `jp_item_descr()` を表示層で使う。
- **実装ポイント**:
  - `include/objclass.h` に `obj_jp_names[]`, `obj_jp_descrs[]`, `jp_item_name()`, `jp_item_descr()` の extern 宣言を置く。
  - `src/objnam.c` の表示系処理で `OBJ_NAME()` / `OBJ_DESCR()` の代わりに `jp_item_name()` / `jp_item_descr()` を利用する。
  - `oc_descr_idx` はシャッフル対象なので、未識別外観は `objects[otyp].oc_descr_idx` 経由で引く。
  - `sys/windows/vs/NetHack/NetHack.vcxproj` と `sys/windows/vs/NetHackW/NetHackW.vcxproj` の両方に `src/obj_jp.c` を追加する。
- **注意**: `objects.h` の `#if 0` で無効なIDを `obj_jp.c` に入れるとコンパイルエラーになる。
- **最低検証**:
  - `msbuild sys\windows\vs\NetHack.sln '/t:NetHack;NetHackW' /p:Configuration=Debug /p:Platform=x64` が成功すること。
  - `binary\Debug\x64\NetHack.exe` と `NetHackW.exe` が生成されること。
  - tutorial が Lua エラー (`Unknown object id`) なしで起動すること。

## 7. 参照先

- **翻訳ガイドライン**: `docs/translation-instructions-ja.md`
- **安全チェックリスト**: `docs/message-translation-safety-checklist.md`
- **用語集**: `docs/translation-glossary-quest.md`

## 8. 技術的注意点 (メッセージ連結自然化)

- 日本語テンプレートで `%s` の直後に助詞（`は/を/に/へ/が/の/と/から`）が来る表示文は、`mon_nam()/Monnam()` ではなく `l_monnam()` を優先する。
- `%s%sから` / `%sは%s%sから` / `%sを%s%sから` のような複合テンプレートは機械置換しない。文脈ごとに語順を手動で整える。
- 英語冠詞を返す補助（`just_an()` など）の結果を日本語文に連結しない。必要なら日本語名詞句を一度バッファへ組み立ててから表示文に渡す。
- 置換後は対象ファイルで `get_errors` を確認し、最低限 `hack.c`, `apply.c`, `trap.c`, `uhitm.c`, `mhitu.c`, `steed.c` の表示文を重点確認する。

## 9. 変更通知コメントの記載ルール

- 変更通知（`Modified by ...` など）を記載する場合は、**対象ファイル形式で有効なコメント構文のみ**を使う。
- プレーンテキストを機械可読ファイル先頭へ直接置かない（パーサが壊れるため）。
- Git pre-commit の自動更新運用では、`dat/` 配下は原則除外するが、`.lua` は対象に含める。
- **XML**: 先頭は必ず `<?xml ...?>` とし、通知コメントはその直後に `<!-- ... -->` で置く。
- **JSON**: コメント構文が無いので通知コメントは入れない（必要なら README やコミットメッセージへ記録）。
- 既存フォーマット仕様を最優先し、通知コメントのためにビルド/解析可能性を下げない。

## 10. NetHack License 2(a) 対応方針

- 改変したファイルには、ファイル形式で有効な方法で改変通知（`Modified by ...` など）を記載する。
- ただしコメント記載できないファイル（例: `dat/` 配下のデータファイル等）は、原本を直接改変しない。
- `dat/` 配下の `.lua` はコメント可能ファイルとして扱い、変更通知コメントの対象に含める。
- コメント不可ファイルの日本語化は、`*_jp` などの別ファイルを作成し、実行時は日本語ファイル優先 + 原本フォールバックで運用する。
- 原本（upstream）データは保持し、追跡可能性のため対応関係を README・コミット履歴・関連ドキュメントに残す。


# context-mode — MANDATORY routing rules

context-mode MCP tools available. Rules protect context window from flooding. One unrouted command dumps 56 KB into context.

## Think in Code — MANDATORY

Analyze/count/filter/compare/search/parse/transform data: **write code** via `ctx_execute(language, code)`, `console.log()` only the answer. Do NOT read raw data into context. PROGRAM the analysis, not COMPUTE it. Pure JavaScript — Node.js built-ins only (`fs`, `path`, `child_process`). `try/catch`, handle `null`/`undefined`. One script replaces ten tool calls.

## BLOCKED — do NOT attempt

### curl / wget — BLOCKED
Terminal `curl`/`wget` intercepted and blocked. Do NOT retry.
Use: `ctx_fetch_and_index(url, source)` or `ctx_execute(language: "javascript", code: "const r = await fetch(...)")`

### Inline HTTP — BLOCKED
`fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, `http.request(` — intercepted. Do NOT retry.
Use: `ctx_execute(language, code)` — only stdout enters context

### WebFetch / fetch — BLOCKED
Use: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)`

## REDIRECTED — use sandbox

### Terminal / run_in_terminal (>20 lines output)
Terminal ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`.
Otherwise: `ctx_batch_execute(commands, queries)` or `ctx_execute(language: "shell", code: "...")`

### read_file (for analysis)
Reading to **edit** → read_file correct. Reading to **analyze/explore/summarize** → `ctx_execute_file(path, language, code)`.

### grep / search (large results)
Use `ctx_execute(language: "shell", code: "grep ...")` in sandbox.

## Tool selection

0. **MEMORY**: `ctx_search(sort: "timeline")` — after resume, check prior context before asking user.
1. **GATHER**: `ctx_batch_execute(commands, queries)` — runs all commands, auto-indexes, returns search. ONE call replaces 30+. Each command: `{label: "header", command: "..."}`.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — all questions as array, ONE call (default relevance mode).
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — sandbox, only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — store in FTS5 for later search.

### Parallel I/O batches
Pass `concurrency: 4-8` to `ctx_batch_execute` and `ctx_fetch_and_index` for network/API batches. Keep `concurrency: 1` for CPU-bound work (test, build, lint). GitHub gh: cap at 4.

## Output

Write artifacts to FILES — never inline. Return: file path + 1-line description.
Descriptive source labels for `ctx_search(source: "label")`.

## Session Continuity

Skills, roles, and decisions persist for the entire session. Do not abandon them as the conversation grows.

## Memory

Session history is persistent and searchable. On resume, search BEFORE asking the user:

| Need | Command |
|------|---------|
| What were we working on? | `ctx_search(queries: ["summary"], source: "compaction", sort: "timeline")` |
| What did we decide? | `ctx_search(queries: ["decision"], source: "decision", sort: "timeline")` |
| What NOT to repeat? | `ctx_search(queries: ["rejected"], source: "rejected-approach")` |
| What constraints exist? | `ctx_search(queries: ["constraint"], source: "constraint")` |

Note: user-prompt history not available.

DO NOT ask "what were we working on?" — SEARCH FIRST.
If search returns 0 results, proceed as a fresh session.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call `ctx_stats` MCP tool, display full output verbatim |
| `ctx doctor` | Call `ctx_doctor` MCP tool, run returned shell command, display as checklist |
| `ctx upgrade` | Call `ctx_upgrade` MCP tool, run returned shell command, display as checklist |
| `ctx purge` | Call `ctx_purge` MCP tool with confirm: true. Warns before wiping knowledge base. |

After /clear or /compact: knowledge base and session stats preserved. Use `ctx purge` to start fresh.

