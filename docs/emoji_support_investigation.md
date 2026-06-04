<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-04. -->
# OPTIONS=glyph による絵文字（Emoji）描画の制限に関する調査報告書

本ドキュメントは、`.nethackrc` などの設定ファイルにおいて `OPTIONS=glyph` を用いて Unicode 補助平面（SMP）のカラー絵文字（例: `U+1F41C` 🐜）などを指定した際、tty版（PDCurses/コンソール版）において正しく描画されない問題についての調査結果をまとめたものです。

将来的に絵文字サポートを有効化したいと考えた際のロードマップおよび技術的障壁についても詳細に記載しています。

---

## 1. 発生する現象
`.nethackrc` に以下のように絵文字を指定しても、ゲーム画面上では絵文字にならず、デフォルトの ASCII 文字が表示されるか、ラテン文字（`Ǵ` など）に文字化けする、あるいは豆腐（`□`）や空白になって表示されます。
```config
OPTIONS=glyph:0/U+0001F41C/255-255-255
```

---

## 2. 根本原因の詳細

この問題は、以下の3つの重層的な制限（パース制限、ゲームエンジン側の描画制限、プラットフォーム側のコンソールAPI制限）が原因で発生しています。

### 原因A: 設定値のパース制限（桁数制限による値の切り捨て）
NetHack 内部の Unicode パース処理を行う [src/utf8map.c:unicode_val()](file:///c:/Users/satok/NetHackJP/src/utf8map.c#L17-L35) には、16進数の文字数を**最大6文字**までしかパースしないというハードコードされた制限があります。

```c
// src/utf8map.c より抜粋
int
unicode_val(const char *cp)
{
    ...
            cp += 2; /* "U+" をスキップ */
            do {
                cval = (cval * 16) + ((int) (dp - hexdd) / 2);
            } while (*++cp && (dp = strchr(hexdd, *cp)) != 0 && ++dcount < 7); // 最大6文字制限
    ...
}
```

* ユーザーが `U+0001F41C` (8文字) と指定した場合、最初の6文字である `0001F4` でループが終了します。
* その結果、内部では `U+01F4`（ラテン大文字 `Ǵ`）として解釈され、本来の `1F41C`（🐜）が取得できません。
* **対策（パースのみ）**: `U+1F41C` のように冗長な `0` を除いて6桁以内で指定すればパース自体は成功しますが、後述の原因BおよびCにより、依然として描画はされません。

### 原因B: 2カラム幅（全角）文字に対する NetHack の描画ロジック上の制限
NetHack のマップシステムは、**「すべての文字が半角1カラム（1セル）に収まること」**を前提として構築されています（[dat/symbols](file:///c:/Users/satok/NetHackJP/dat/symbols#L820-L822) にもその旨がコメントされています）。

```
# Emoji support often is problematic, and wide glyphs occupy two display
# columns, which NetHack does not support.
```

1. Cursesライブラリ（PDCursesMod）は、幅が 2 カラムの文字（カラー絵文字など）を検知すると、右隣のセルにダミー文字 `DUMMY_CHAR_NEXT_TO_FULLWIDTH` を自動挿入して表示領域を確保します（[pdcurses/addch.c](file:///c:/Users/satok/NetHackJP/lib/pdcursesmod/pdcurses/addch.c#L680-L685)）。
2. しかし、NetHack 側はこれを感知しないため、次の処理でその右隣のセル（例: 隣の床 `.` や壁）に通常通り文字を描画しようとします。
3. この上書き描画処理により、描画された絵文字の右半分が破壊され、コンソール側の表示データが破損します。

### 原因C: Windows コンソール API（`WriteConsoleOutput`）の構造的制限
Windows の標準コンソール（`cmd.exe` や旧 `powershell.exe` など）で動作する tty版（`NetHack.exe`）は、画面出力に Windows API の `WriteConsoleOutputW` を使用して描画します。

* この API が受け取る文字データ構造体 `CHAR_INFO` は、**1セルあたり1つの 16ビット `WCHAR`（UTF-16コードユニット）**しか保持できません。
* `U+10000` 以上の文字（絵文字の多く）は UTF-16 においてサロゲートペア（16ビット値2つ）を必要とするため、この `CHAR_INFO` の制限により、1セルの中にサロゲートペア文字を書き込むことがシステム上不可能となっています。
* そのため、PDCursesMod の wincon（Windows コンソール）ドライバを介した出力では、絵文字は本質的に文字化けや豆腐になってしまいます。

---

## 3. 将来的に絵文字サポートを実現するための対応ロードマップ

もし将来的に絵文字サポートを実装する場合、以下の対応が必要となります。

### ステップ1: パースロジックの改善 (NetHack側)
* [src/utf8map.c:unicode_val()](file:///c:/Users/satok/NetHackJP/src/utf8map.c#L17-L35) の文字数判定制限（`dcount`）を緩和、もしくは `0` パディングを自動でトリムして 32ビット値の限界値（`0x10FFFF`）までパースできるように修正する。

### ステップ2: 2カラム文字の競合回避 (NetHackおよびCurses側)
* NetHack のマップ描画処理において、2カラム文字を描画した場合は、その直後の座標への描画をスキップする（あるいはスペースで埋めて上書きさせない）といった排他制御ロジックを実装する。

### ステップ3: 表示エンジンの移行 (Platform側)
Windows 標準コンソール API（`WriteConsoleOutput`）を使用する限り、サロゲートペア文字を1セルで表現することはできません。この問題を解決するには、以下のいずれかの表示エンジン（window port）に切り替える必要があります。

1. **Windows Terminal (UTF-8ダイレクト出力) の利用**:
   * 標準コンソール API ではなく、仮想ターミナルエスケープシーケンス（VT Esc Code）を用いて UTF-8 のストリームとして絵文字を出力するモードに変更する。これにより、サロゲートペアの問題は完全に解消されます。
2. **別の Curses ドライバ（SDL2 / OpenGL版）の採用**:
   * PDCursesMod は `wingui`, `sdl2`, `gl` などのグラフィックスバックエンドもサポートしています。これらのバックエンドは独自のフォントレンダラを使用するため、Windows コンソールの `CHAR_INFO` 制限を受けず、カラー絵文字を含む TrueType フォントを正しく描画することが可能です。
3. **GUIポート（NetHackW / Qt）の利用**:
   * `NetHackW.exe` など、Windows ネイティブの GUI 機能を使用するポートでは、フォントフォールバック機能が働くため、適切な Unicode フォントをシステムにインストールすれば、比較的容易に絵文字や追加シンボルの描画が可能になります。
