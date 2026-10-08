<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-04. -->
# NetHackJP X11 ポート XIM (X Input Method) 実装計画

## 背景

NetHackJP の Linux/WSL X11 ポート (`win/X11`) は、入力処理に `XLookupString()` を直接使用しているため、fcitx5 / ibus / IIIMF 等のインプットメソッド（IM）サーバと通信できない。結果として、プレイヤー名入力・記念碑・願い・虐殺等の日本語入力が必要な場面で日本語が打てない。

本家は NetHack 5.0 においても XIM 対応をしておらず、本リポジトリで独自実装する。

## 設計方針

| 項目 | 決定 |
|---|---|
| **入力対象範囲** | 全入力経路（`map_input` / `key_event_to_char` / AsciiText getlin） |
| **XIMインプットスタイル** | `XIMPreeditNothing \| XIMStatusNothing`（プリエディット／ステータスウィンドウは OS・fcitx5 に任せる） |
| **フォールバック** | `XOpenIM` 失敗時は `XLookupString` に完全フォールバックし、後方互換性を維持 |
| **ビルドフラグ** | `HAVE_XIM` を `sys/unix/hints/linux-jp` で `NHCFLAGS += -DHAVE_XIM` として定義 |
| **モジュール構成** | 新規 `win/X11/winxim.c`（XIM インフラ層）+ 既存ファイルの `#ifdef HAVE_XIM` ブロック |
| **実行時トグル** | `OPTIONS=xim:off` で完全無効化（Phase 7） |

## Phase 構成

各 Phase は独立したコミットとし、問題発生時は単独 `git revert` 可能。

### Phase 0：設計文書化と事前整理（コード非改変）

* `AGENTS.md` に XIM 関連ルール下書きを追記
* `sys/unix/hints/linux-jp` に `HAVE_XIM` フラグ準備（値は未設定）
* `DEVELOPMENT.md` §4.8 の誤記述（"`XtSetLanguageProc` により XIM 入力が機能"）は Phase 6 で一括訂正

### Phase 1：XIM インフラ層

* 新規 `win/X11/winxim.c` を作成し、以下 API を実装（`#ifdef HAVE_XIM` ガード）：
  * `xim_init(Display *)` — `XSetLocaleModifiers("")` → `XOpenIM`
  * `xim_cleanup(void)` — `XCloseIM`
  * `xim_create_ic(Widget)` / `xim_destroy_ic(XIC)` — IC ライフサイクル
  * `xim_focus_in(XIC)` / `xim_focus_out(XIC)` — フォーカス管理
  * `xim_lookup_utf8(...)` — `Xutf8LookupString` のラッパー
* `include/winX.h` に extern 宣言を追加
* `win/X11/winX.c:1687` の `XtSetLanguageProc` 直後で `xim_init` 呼び出し
* `win/X11/winX.c:1776` `X11_exit_nhwindows` 末尾で `xim_cleanup`
* `sys/unix/hints/linux-jp` で `-DHAVE_XIM` を定義
* マーカータグ: `/* NetHackJP: XIM integration */`

### Phase 2：マップ入力経路の XIM 化

* `win/X11/winmap.c` の `map_input()` の `XLookupString` を `xim_lookup_utf8` に置換
* `inbuf[]` へのマルチバイト UTF-8 キューイング（バイト単位）。Meta ビット（`0x80`）は先頭バイトのみ付与
* `xic == NULL` または `Xutf8LookupString` 失敗時は `XLookupString` にフォールバック
* マーカータグ: `/* NetHackJP: XIM-aware map input */`

### Phase 3：AsciiText 経路の検証

* `dialogs.c:155` の `XtNinternational=True` のまま Xaw の内部実装に任せる
* 検証のみ。問題が出ても修正は行わず Phase 4 以降で対応
* `XtNfont` 取得の NULL ガードは既存 `5c70f767d` で対応済み

### Phase 4：`key_event_to_char` 経路のマルチバイト対応

* `key_event_to_char()` を `int (XKeyEvent *, char *buf, int bufsz)` に拡張
* 呼び出し側 8 箇所を更新：
  * `win/X11/winX.c:2280` `yn_key()`
  * `win/X11/winmisc.c:198` `role_key()`
  * `win/X11/winmisc.c:242` `race_key()`
  * `win/X11/winmisc.c:277` `gend_key()`
  * `win/X11/winmisc.c:310` `algn_key()`
  * `win/X11/winmisc.c:1836` `ec_key()`
  * `win/X11/winmenu.c:252` `menu_key()`
  * `win/X11/wintext.c:120` `key_dismiss_text()`
* 各呼び出し側で「単一 ASCII」「マルチバイトキュー」の分岐を実装
* マーカータグ: `/* NetHackJP: XIM-aware key_event_to_char */`

### Phase 5：フォーカスイベントと IC ライフサイクル管理

* `nh_XtPopup()` / `nh_XtPopdown()` で IC フォーカス切替
* toplevel / 各 popup / 各 dialog ごとに専用 IC を作成・再利用
* `xim_get_ic_for_widget()` ヘルパで Widget→XIC の弱参照マップ提供
* マーカータグ: `/* NetHackJP: XIM focus tracking */`

### Phase 6：ドキュメント・ビルド設定の永続化

* `DEVELOPMENT.md §4.8` の `XtSetLanguageProc` 説明を訂正し、`§4.10` を新設
* `AGENTS.md` に XIM 関連ルールを本採用
* `sys/unix/hints/linux-jp` に fcitx5 / ibus 推奨パッケージ案内
* `sys/unix/build_wsl.sh` の `apt install` リスト更新
* `README.md` の Linux 版起動手順を更新
* `.nethackrc.X11` サンプルに `OPTIONS=xim:true` 追加

### Phase 7：OPTIONS=xim トグル導入

* `src/options.c` で `xim` オプション登録（既存 `mouse_support` と同パターン）
* `include/flag.h` に `iflags.use_xim` フラグ追加
* `win/X11/winxim.c` の `xim_init` / `xim_create_ic` でフラグ参照
* マーカータグ: `/* NetHackJP: OPTIONS=xim toggle */`

### Phase 8：統合検証

* WSL2 + fcitx5 環境での全入力経路動作確認 — **完了**（日本語名入力確認済み）
* fcitx5 未起動時のフォールバック動作確認 — **完了**（stderr で `XIM: XOpenIM failed` → `XLookupString` フォールバック）
* `OPTIONS=use_xim:off` での完全無効化確認 — **完了**（Phase 7 で `initoptions_init` 前にデフォルト 1、options パース後に上書き可能なフラグ処理、`xim_init` でトグル判定）
* upstream NetHack-5.0 の XIM 関連追従チェック — **完了**（`upstream/NetHack-5.0:win/X11/` には XIM 関連コードなし、コメント中の "input method" 文字列のみヒット。本独自拡張は引き続き有効）

## 実装ステータス（全 Phase 完了）

| Phase | 内容 | 状態 |
|---|---|---|
| 0 | 文書整備のみ | ✓ |
| 1 | XIM インフラ層（`win/X11/winxim.c` 新規作成） | ✓ |
| 2 | `win/X11/winmap.c` の `map_input()` を XIM 経路に置換 | ✓ |
| 3 | AsciiText 経路検証 → XtNinternational で fcitx5 engage せず失敗確認 | ✓ |
| 3+ | `win/X11/wingetlin.c` 自前 getlin ダイアログ実装 | ✓ |
| 4 | `key_event_to_utf8` マルチバイト対応 + 8 呼び出し側更新 | ✓ |
| 5 | IC フォーカス管理（`xim_focus_in/out` + `nh_XtPopdown`） | ✓ |
| 6 | `DEVELOPMENT.md` §4.8 訂正 + §4.11 新設 / `AGENTS.md` / `README.md` / `.nethackrc.X11` | ✓ |
| 7 | `OPTIONS=use_xim` 実行時トグル | ✓ |
| 8 | 統合検証（本セクション） | ✓ |

WSL2 + fcitx5 環境で日本語入力が実用的に動作することを確認。fcitx5 不在時は ASCII フォールバックで英語入力が継続可能。`OPTIONS=use_xim:off` で XIM 完全無効化も可能。

## 既知の制限事項

### コア nhgetch() の1byte=1コマンド前提

`nhgetch()` は1回の呼び出しで1コマンドを消費する前提のアーキテクチャのため、IME確定文字列（複数バイト）が来た場合、各バイトが独立したコマンドとして解釈される：

* **影響あり**：マップ画面で `h`/`j`/`k`/`l` 等の移動中に日本語確定 → 各バイトが独立移動コマンド扱い
* **影響なし**：`#名前` / `#記念碑` / `#虐殺` 等の getlin ダイアログは AsciiText Widget が確定後にまとめて文字列を取得するため正常動作

この制限は AGENTS.md に明記し、将来 `string mode` API 追加時に再設計する。

### Xaw AsciiText の `XtNinternational` 制約

X Athena Widgets の国際化対応は古く、preedit 中の Enter 衝突等の既知問題がある。本実装では `XtNinternational=True` のままとするが、問題が大きい場合は Phase 4 以降で getlin 経路のみ Qt 風の独自実装に置き換える選択肢もあり。

### WSLg / XWayland の XIM 対応

WSL2 + WSLg の XIM 対応は XWayland 経由のため、WSL のバージョンやディストリビューションによって fcitx5 が動かない可能性がある。動かない環境では代替手段（curses ポート）を案内。

### getlin ダイアログの IM 統合に関する修正履歴（2026-09-04, DEVELOPMENT.md §4.12）

自前 getlin ダイアログ (`wingetlin.c`) の運用で発覚した問題と修正：

* **XtNinternational での fcitx5 engage 失敗**（§4.11）→ `labelWidgetClass` ベースの自前ダイアログに全面置換
* **チェーン制約欠如によるフォーム縮潤・ボタン枠線不可視**（§4.12）→ 全子に chain hints + `XtNresizable=True`、`XtNborderWidth=0` の撤去
* **ESC 経路の `client_data` 不整合クラッシュ**（§4.12）→ `xim_getlin_cancel_button` へ `state->form` を明示渡し
* **確定文字取りこぼし・stale IC・入力欄最低幅**（§4.12）:
  - キーハンドラを XIM lookup 最優先に再構成（Enter/Space キーイベントに乗る commit を確実に捕獲。確定時にダイアログが閉じる問題を解消）
  - IC キャッシュを Window ID 連動に（`positionpopup()` が開くたび Window を再作成するため、stale IC により fcitx5 が disengage し全入力が不能になる問題を解消）
  - MapNotify フォーカスハンドラを常設化し `CreateXimDialog()` で realize 前に登録（旧 1 回きり型は初回オープンで発火せず、2回目以降も 1 オープン遅れで不定）
  - 入力欄は空欄時でも半角10文字分以上の幅を保証（`X11_label_string_width()` による実測、全削除で最低幅へ復帰）
* **第2ラウンド修正**（§4.12）:
  - 明示幅を label/bitmap 更新の**後**に別 `XtSetValues` で適用（Xaw Label の自動リサイズが同一呼び出し内の幅指定を上書きするため）
  - XIM lookup の結果を status/keysym で識別（`XLookupChars` のみ追記、編集キーの素の変換 `\r`/`\b`/0x7F が文字として挿入される問題を解消）
  - ダイアログの X フォーカス取得前に保存し `XimDialogReleaseInputFocus()`（`nh_XtPopdown` 経由）で復元（PointerRoot ポインタ追従モデルの維持）
  - **`winmap.c::map_input` の XIM 経路を削除**（Phase 2 実装の取り止め）。メインウィンドウは IC を focus しないため IM が engage する経路が構造的に消滅し、プレイ中に日本語入力 UI が勝手に起動する問題を解消。日本語入力は getlin / askname ダイアログ専用。

## ロールバック戦略

各 Phase は独立コミット。問題発生時は該当 Phase を `git revert` で単独巻き戻し。`HAVE_XIM` が未定義なら XIM 関連コードはビルドから完全に除外され、コードパス上は存在しない状態に戻る（`#ifdef` の安全ガード）。

## スケジュール目安

| Phase | 内容 | 想定規模 |
|---|---|---|
| 0 | 文書整備のみ | 0.5h |
| 1 | winxim.c 骨格 + ビルドフラグ | 1.5h |
| 2 | winmap.c XIM 化 | 1h |
| 3 | AsciiText 経路検証 | 0.5h |
| 4 | key_event_to_char リファクタ + 呼び出し側更新 | 2.5h |
| 5 | フォーカス管理 | 1h |
| 6 | ドキュメント整備 | 1.5h |
| 7 | OPTIONS=xim トグル | 0.5h |
| 8 | 統合検証 | 1h |
| **合計** | | **約9-10h** |

## アップストリーム追従方針

* 本家 NetHack-5.0 に XIM 対応が入った場合：本独自拡張を取り消してアップストリームに追従する
- `git fetch upstream NetHack-5.0` で定期的に確認
- 重複する部分のみ取り消し、不足分は本独自拡張で補う