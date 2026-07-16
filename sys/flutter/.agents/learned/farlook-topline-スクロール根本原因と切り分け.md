# farlook スクロール問題 — 根本原因特定と切り分けの教訓

- **日付**: 2026-07-16
- **報告者**: ksatou <satokiyon@users.noreply.github.com>
- **プロジェクト**: NetHackJP-Android (Flutter ポート)
- **症状分類**: メッセージウィンドウのスクロール・履歴汚染
- **NetHackJP-Android 固有マーカー**: `/* NetHackJP: ... */` (C コード)

## 症状

Flutter ポートで farlook (`/`) 中に、 カーソルを動かすたびにメッセージ領域 (2 行) のテキストが**スクロール**し、 過去のカーソル位置の説明が下から押し出されて消える。 さらに `^P` 履歴にも `カーソルを怪物、 物体、 または場所に移動して.` 等の farlook 内部プロンプトが通常メッセージとして積まれるようになり、 履歴を汚染する。

ユーザーは「期待する動作は、 farlook モードでは、 カーソルを動かすたびにメッセージ表示行の一番下が上書き更新される」 (Windows 版相当の挙動) を求めた。

## 根本原因 (要約)

`sys/android/winandroid.c:71-72` の `and_procs.wincap2` から **`WC2_SUPPRESS_HIST` フラグが欠落** していた。

`src/pline.c:77`:
```c
if ((gp.pline_flags & SUPPRESS_HISTORY) != 0
    && (windowprocs.wincap2 & WC2_SUPPRESS_HIST) != 0)
    attr |= ATR_NOHISTORY;
```

`WC2_SUPPRESS_HIST` が 0 のため、 `custompline(SUPPRESS_HISTORY, ...)` 経路のすべてで `attr |= ATR_NOHISTORY` が実行されず、 以下の出力が **通常 pline として履歴に積まれる** 状態になっていた:
- `pager.c:2276` farlook verbose プロンプト
- `pager.c:2280` farlook short プロンプト
- `getpos.c:844` 操作説明プロンプト (verbose 時)
- `getpos.c:861` show_goal_msg プロンプト
- `getpos.c:652` autodescribe 出力

Flutter 側は `attr & 0x0020` (ATR_NOHISTORY) で topline 判定しているため、 0x20 ビットが立たなければ必ず履歴に積まれ、 ユーザー視線では「メッセージがスクロール」「^P 履歴に出る」 という症状として出ていた。

## 切り分けで分かったこと (5 つの教訓)

### 教訓 1: `wincap2` のフラグ欠落は `custompline` 経路を全滅させる

`WC2_SUPPRESS_HIST` のような `custompline` 判定フラグが `wincap2` から欠落していると、 **Flutter 側だけが topline 対応しても `custompline(SUPPRESS_HISTORY, ...)` 経路が全滅する**。 表面上は「Dart 側の topline 判定が効いていない」ように見えるが、 実態は C コアから `ATR_NOHISTORY` ビットが立っていないため Dart 側ロジックに到達しても判定材料が無いだけである。

これは `pager.c` のソース修正や Dart 側デバッグでは再現せず、 結局 `wincap2` (`sys/` 配下のウィンドウポート初期化コード) まで掘らないと根本原因に到達しない。 「NetHack メッセージング系の挙動が想定と違う」と感じたら、 **真っ先に `wincap2` のフラグ集合を確認** するのが鉄則。

### 教訓 2: Dart 側 `debugPrint` での `attr` hex 値出力が切り分けの決定打になった

C 側ログ (`flutter_putstr`) には attr が出ない (もしくは見落としやすい) ため、 **「C 側が `ATR_NOHISTORY (0x20)` を Dart に送っているか?」 を Dart 側で直接判定する** のが最も確実だった。 具体的には `nethack_screen.dart` の `putString` / `putMixedWithTile` に以下を仕込む:

```dart
debugPrint('putString win=$winId attr=0x${attr.toRadixString(16)} msg="$msg"');
```

これで「`attr=0x00` = 通常 pline 経路で来ている」「`attr=0x20` = topline 経路」 を即座に判別できる。 verbose プロンプトなど `custompline(SUPPRESS_HISTORY, ...)` 経路が全部 `attr=0x00` だったため、 「C コア側が topline 判定で脱落している」 ことが決定打になった。

`debugPrint` は `package:flutter/foundation.dart` 標準で、 `print` より長い文字列を自動分割してくれるため推奨される。 `adb logcat` と `flutter run` コンソール両方に出力される点も便利。 **原因特定後は必ず削除してからコミット** する (AGENTS.md 方針 6)。

### 教訓 3: デバッグ検証マーカーは「コミット分離」する

切り分けでは `pager.c:2301, 2303` に `putstr(WIN_MESSAGE, ATR_NONE, "[nethackjp-farlook-marker-v1]")` 等の検証マーカーを仕込んだが、 これを **root cause fix コミットに含めてしまい**、 後に `git reset --hard` + 再 commit で分離する手間が発生した。

正しい運用は「デバッグ用マーカーは **別コミットに分離** しておき、 切り分け確定後に revert する方が綺麗」。 具体的には:
1. 検証マーカー投入コミット (`[debug]` プレフィックス等)
2. 切り分け過程の各コミット
3. 検証マーカー除去コミット
4. 最後の root cause fix コミット

の 4 段階に分けると、 レビュー時に「デバッグマーカーは将来 revert する一時コミット」 と一目で分かる。

### 教訓 4: WSL ビルドだけでは反映確認にならない (gradle cxx ビルドの存在)

`sys/nethack_flutter/android/app/src/main/cpp/CMakeLists.txt` が `pager.c` などの C ソースを **gradle の cxx ビルド (NDK + CMake) で再コンパイル** する。 これが `sys/nethack_flutter/build/app/intermediates/cxx/.../libnethack.so` に出力され、 APK にはこちらの `libnethack.so` が組み込まれる。

WSL の `make ABI=arm64-v8a install` で `sys/android/app/libs/arm64-v8a/libnethack.so` (13.4MB) を作っても、 `flutter clean` + `flutter run` 時に gradle 側で **別物 (12.8MB) を作り直す**。 サイズ差から両者が別物だと判明した。 つまり **WSL ビルドだけでは反映確認にならない**。 C ソースを変更した後は必ず `flutter clean` → `flutter run` で Android 端末にインストールし直す。

教訓: **「`sys/android/app/libs/<ABI>/libnethack.so` (WSL 製)」と「`sys/nethack_flutter/build/app/intermediates/cxx/.../libnethack.so` (gradle 製)」は別物**。 ファイルサイズ (ls -l) で即座に判別できる。 gradle 製の方が若干小さい (Flutter 側のフラグやシンボル定義が微妙に違うため)。

### 教訓 5: 「putmixed が呼ばれない」 vs 「putmixed は呼ばれているが別経路で通常 pline 化」 の切り分け

`pager.c:2300` の `putmixed(WIN_MESSAGE, ATR_NOHISTORY, out_str)` は attr=32 を直接 putstr 経路に送る (チェック不要)。 これが呼ばれるなら Dart 側に 0x20 が届くはずだが、 0x00 が届いている = **putmixed 自体が呼ばれていない** = `if (found)` に入っていない = `do_screen_description` が `found=0` を返している (つまりヒットなし)、 ということになる。

今回は違っていた (全 pline 経路で attr=0x00 だったため `wincap2` 欠落が原因) が、 **「`putmixed` 経路で attr=0x20 が来ているのに履歴に積まれる」 という症状なら C コアの ATR ビット付け替え側に問題、 「attr=0x00 が来る」 という症状なら呼び出し元 or フラグ欠落側に問題** という切り分けは将来にも有用。

Dart 側 `debugPrint` で `attr=0x${attr.toRadixString(16)}` を確認 → C 側 `putmixed` の attr 引数を静的読み (Grep 等) → 呼び出し経路を逆引き、 という 3 段で原因箇所に到達できる。

## 関連するコミットハッシュ (NetHackJP-Android 側)

時系列順 (古い → 新しい):

| ハッシュ | コミット | 役割 |
|---------|---------|------|
| `708eca318` | farlook: カーソル移動時の説明に ATR_NOHISTORY を付与 | 1st attempt: `pager.c:2300` の `putmixed` に `ATR_NOHISTORY` 付与 (効果なし、 後で topline 化に置換) |
| `9c1116774` | flutter: flutter_save_message を ATR_NOHISTORY で skip | 1st attempt: Flutter 側で履歴スキップを追加 |
| `a0dc1e979` | flutter: topline (ATR_NOHISTORY) 状態管理と表示を実装 | 1st attempt: topline 状態管理 |
| `91510d14f` | farlook: "カーソルを選んで" プロンプトも topline 化 | 1st attempt: getpos.c:861 show_goal_msg への `custompline(SUPPRESS_HISTORY, ...)` 追加 |
| `7da0797e5` | flutter: wincap2 に WC2_SUPPRESS_HIST を追加 | **root cause fix** |
| `3bdf9d72c` | farlookモードのときflutter版ではメッセージスクロールしないようにtoplineとして扱えるように修正 | upstream へのマージ用クリーンアップ |
| `9cc800a67` | Merge updates from NetHackJP(main) | upstream マージ |

## NetHackJP (本家) への反映内容

`pager.c` の farlook verbose/short プロンプトに `/* NetHackJP: ... */` マーカー (AGENTS.md 方針 5 準拠) でマーキングしつつ修正。 具体的には `pager.c:2276, 2280` の `custompline(SUPPRESS_HISTORY, ...)` 化と、 `pager.c:2300` の `putmixed` 第 2 引数への `ATR_NOHISTORY` 明示指定 (本家側の `wincap2` には元々 `WC2_SUPPRESS_HIST` があるため、 こっちが本来の挙動)。

これにより本家側でも topline 表示が確実になり、 「プロンプトが履歴に積まれる」 副作用を upstream レベルで抑える。

## チェックリスト (今後同様の症状が出たら)

- [ ] **W1**: 「NetHack メッセージング系の挙動が想定と違う」と感じたら、 `wincap2` のフラグ集合 (`sys/<platform>/win<platform>.c`) を確認
- [ ] **W2**: Dart 側 `nethack_screen.dart` の `putString` / `putMixedWithTile` に `debugPrint('attr=0x${attr.toRadixString(16)}')` を仕込んで attr hex 値を確認
- [ ] **W3**: デバッグ検証マーカー投入は **別コミットに分離** (root cause fix コミットに混入させない)
- [ ] **W4**: C ソース変更後は **WSL ビルドだけでは反映確認にならない**。 `flutter clean` → `flutter run` で gradle cxx ビルドをトリガーする
- [ ] **W5**: 「`putmixed` 経路で attr=0x20 が来ているのに履歴に積まれる」 → C コアの ATR ビット付け替え側に問題。 「attr=0x00 が来る」 → 呼び出し元 or フラグ欠落側に問題

## 関連ドキュメント

- `AGENTS.md` 方針 6 (デバッグ用一時コード・ログ出力のクリーンアップ)
- `AGENTS.md` 方針 7 (Dart 側デバッグログの出力先: `debugPrint` を `adb logcat` / `flutter run` コンソールに出す)
- `AGENTS.md` 「NetHack C コア ↔ Flutter FFI におけるウィンドウ API とタイル描画の設計方針」 (putmixed 拡張パターン)
- `sys/nethack_flutter/AGENTS.md` (Flutter 移植版固有の C スレッド連携・UI 同期設計方針)

## 学んだ教訓の一般化

`wincap` / `wincap2` のような **ウィンドウポート capability フラグ** は NetHack の「内部挙動 (履歴・自動選択・色表示など)」 を細かく制御する。 これらフラグが欠落していると、 上位レイヤ (Flutter 側) でいくら対応しても「想定通り動かない」 状態になる。 新しいポート (Flutter, WebAssembly 等) を起こす際は、 **既存の全 `wincap` / `wincap2` フラグを `windows.c` の `genl_xxx` 実装に揃える** ことが「Windows 版相当の挙動」 の最低条件である。
