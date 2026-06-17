<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-17. -->
# NetHack 5.0 日本語化非公式プロジェクト

NetHackJPは、ローグライクゲームの金字塔 [NetHack](https://www.nethack.org/)5.0 を日本語で快適にプレイできるようにすることを目的とした非公式プロジェクトです。(対象OSはWindowsのみ)

<figure>
   <figcaption>GUI版 Nevanda_5.0.0_32x32タイル使用</figcaption>
   <img width="1209" height="787" alt="2026-06-14_16h55_40" src="https://github.com/user-attachments/assets/021ab227-be59-469c-8243-099f6c57c640" />
</figure>

<figure>
   <figurecaption>コンソール版。`OPTIONS=windowtype:curses,align_message:right`指定</figurecaption>
   <img width="1283" height="588" alt="2026-06-04_20h10_10" src="https://github.com/user-attachments/assets/58e277fb-4abd-46e6-a839-d7538497a446" />
</figure>

<figure>
     <figurecaption>コンソール版</figurecaption>   
     <img width="1058" height="607" alt="2026-06-02_05h25_26" src="https://github.com/user-attachments/assets/ab664586-d185-4a1c-b23e-6807ec676d9a" />
</figure>

---

## 🎮 プレイヤー向け情報（ゲームの始め方）

さっそくダウンロードして[NetHack](https://www.nethack.org/)を日本語で遊んでみてください!

### 1. 導入手順

ゲームをプレイするには、[GitHubのReleasesページ](https://github.com/satokiyon/NetHackJP/releases) からビルド済みのWindows用実行ファイル（`NetHack.exe` / `NetHackW.exe`）を含むZIPファイルをダウンロードしてください。

※最新の開発版をプレイしたい場合はご自身でビルドする必要があります（ビルド方法は後述の「開発者向け情報」を参照してください）。

#### NetHackJP起動手順

※参考 : [NetHack 5.0.0 Windows Port](https://nethack.org/v500/ports/download-win.html)

1. ダウンロードしたZIPファイルをすべて展開してください。
   （※ZIPファイルの中にファイルがある状態で実行ファイルを起動しないでください）

2. 必要であれば、ご自身の環境に合わせてNetHackの設定ファイルを編集してください。
   NetHackに関連するフォルダの場所と名前は、次のコマンドで確認できます。
   ```cmd
   nethack.exe --showpath
   ```
   設定は `.nethackrc` を編集してください。一度NetHackを起動すると、`nethackrc.template` からコピーされて自動作成されます。
   その後、作成された `%USERPROFILE%\NetHackJP\.nethackrc` を編集してください。

3. 次のどちらかのファイルを起動してください。
   * **`NetHack.exe`** （コンソール版）
   * **`NetHackW.exe`** （GUI版）


- `.nethackrc` に設定できる各種オプションやゲーム内容に関する説明は、`Guidebook_JP.txt` を参照してください。

---

### 2. 日本語入力と対応機能
Windows版では、ゲーム内での日本語入力・表示に対応しています。以下の項目で日本語と英語のどちらも使用可能です。
* 主人公キャラの名前
* アイテムやモンスターへの命名（名前付け）
* 「願い（wishing）」の指定
* 「虐殺（extinction）」の指定
* データベースの検索

---

### 3. タイルセット（画像）で遊ぶ
NetHack はテキスト（ASCII文字）だけでなく、美しいグラフィック（タイル）でプレイすることも可能です。

#### 設定手順
1. 好みのタイルセットをダウンロードし、BMP形式に変換します。
   * 参考リンク
     * [NetHackWiki Tileset 一覧](https://nethackwiki.com/wiki/Tileset)
     * [Geoduck Tile Set](http://www.geoduckthings.net/nhack/nhack.html)
2. `.nethackrc` を開き、以下の例のように設定を追記または修正します。
   ```ini
   OPTIONS=map_mode:tiles
   OPTIONS=tile_file:Nevanda_5.0.0_32x32.bmp
   OPTIONS=tile_width:32
   OPTIONS=tile_height:32
   ```
   * `tile_file`: 使用する BMP ファイル名（または絶対パス）を指定します。
   * `tile_width` / `tile_height`: タイルのピクセルサイズ（例: 32x32 なら `32`）を指定します。

#### タイル画像の配置場所
* 相対パスで指定する場合、実行ファイル（`NetHack.exe` / `NetHackW.exe`）と同じフォルダに置くのが確実です。
* サブフォルダに置く場合は `OPTIONS=tile_file:tiles/your_tiles.bmp` のように相対パスで指定できます。

---

### 4. 効果音（サウンド）を鳴らす
NetHackでは、ゲーム内のメッセージに合わせてお好みの効果音（WAVファイル）を鳴らすことができます。

#### 設定手順
1. 効果音として使用したいWAVファイルを用意し、任意のフォルダ（例: `sounds`）に配置します。
2. `.nethackrc` を開き、以下の設定を追記または修正します。
   ```ini
   # 効果音ファイルが置かれているフォルダの絶対パスを指定します
   SOUNDDIR=C:\path\to\NetHackJP\sounds

   # SOUND=MESG "メッセージの正規表現" "ファイル名" 音量(0-100)
   SOUND=MESG "(ド♪)" "se_squeak_C.wav" 100
   SOUND=MESG "地雷が爆発した[!！]" "sepack/sepack_12_damage_floor.wav" 100
   SOUND=MESG "は(上|下)の階へ逃げた[!！]" "sepack/sepack_23_escape.wav" 100
   ```
   * `SOUNDDIR`: WAVファイルが格納されているベースとなるディレクトリを指定します。
   * `SOUND=MESG`: メッセージに対する効果音のマッチング設定です。
     * `"メッセージの正規表現"`: ゲーム内で表示されるメッセージ（正規表現が使用可能です）。
     * `"ファイル名"`: 再生するWAVファイル名（`SOUNDDIR` からの相対パス）。
     * `音量`: 0〜100 の数値で指定します。

---

### 5. GUIモードのレイアウトカスタマイズ (NetHackJP独自機能)
GUI版（`NetHackW.exe`）では、ステータスウィンドウやメッセージウィンドウの配置とサイズを自由にカスタマイズできます。特にステータスウィンドウを左右に配置した際、項目を縦に並べて表示する機能が追加されています。

#### 設定手順
`.nethackrc` を編集して以下のオプションを組み合わせます。

*   **ステータスウィンドウを縦並びにする**
    `OPTIONS=align_status:left` (または `right`) を指定すると、ステータス項目が縦1列に並びます。
    ※HP/最大HP、魔力/最大魔力、レベル/経験値は自動的に同じ行にグループ化され、見やすく表示されます。

*   **ウィンドウサイズを個別に指定する**
    以下の専用オプションを使用して、メッセージウィンドウとステータスウィンドウのサイズを独立して設定できます。
    *   `msw_msg_cols` / `msw_msg_rows`: メッセージウィンドウの幅（列）/ 高さ（行）
    *   `msw_stat_cols` / `msw_stat_rows`: ステータスウィンドウの幅（列）/ 高さ（行）
    ※従来の `term_cols` / `term_rows` も使用可能ですが、複数のウィンドウで異なる値を設定したい場合は上記の専用オプションを使用してください。

#### 設定例
```ini
# メッセージウィンドウを上側に6行分で表示
OPTIONS=align_message:top,msw_msg_rows:6

# ステータスを右側に幅15文字分で表示（縦並び）
OPTIONS=align_status:right,msw_stat_cols:15
```

より多くの設定例が `.nethackrc`（または `nethackrc.template`）に記載されていますので、そちらも参考にしてください。その他の詳細なオプション等については `Guidebook_JP.txt` を参照してください。

----

### 6. セーブデータ一覧画面の表示とロード(NetHackJP独自機能)
ゲーム起動時に、セーブファイルが存在すればファイル一覧を表示し、その中から選択してゲームを再開できます。

オリジナルでは、名前を入力する際に空入力(Enterを押すだけなど)を10回繰り返すと、セーブファイル一覧が表示されていましたが、NetHackJPでは最初から(または空入力を1回だけで)セーブデータを選択する画面を表示するようにしました。

また、セーブデータから職業、種別、性別、属性を読み取るようにしました。オリジナルでは名前だけしか読めない場合があったのを暫定処置的に修正しています。なお、オリジナルがこの処理を変更・修正されればそれに追従する予定です。詳細は[DEVELOPMENT.md](DEVELOPMENT.md)に記載しています。

---

## 💖 プロジェクトの支援について

このプロジェクトは個人によって開発・保守されています。
もし本プロジェクトが気に入ったり、今後の継続的な開発を応援したいと感じていただけた場合は、
任意の支援(チップ)をいただけると大変励みになります。

[![Sponsor satokiyon](https://img.shields.io/badge/Sponsor-satokiyon-EA4AAA?style=flat-square&logo=github-sponsors&logoColor=white)](https://github.com/sponsors/satokiyon)

※開発活動への支援は上記のボタンや本リポジトリの「Sponsor」ボタンから行えます。


---

## 🛠️ 開発者向け情報 / 翻訳方針 / リポジトリ運用
開発者ビルドの手順、オブジェクト名ローカライズ方針、翻訳時のポイントやGit運用メモなどの開発者向けの情報は、[DEVELOPMENT.md](DEVELOPMENT.md) を参照してください。

---

## ⚖️ ライセンス
本リポジトリは、オリジナルの NetHack 同様、NetHack General Public License に準じます。
ライセンスに関する詳細な情報は以下を参照してください。

* ライセンス本文: [dat/license](dat/license)
* サブモジュール等の第三者コンポーネント: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES)

---

## 他の日本語化プロジェクト
* [JNetHack](https://github.com/jnethack): 言わずと知れたNetHack日本語版の偉大なる総本山
* [NetHack-brass](https://github.com/youkan700/NetHack-brass): 3.4.3ベースを日本語化してさらにいろいろ改造したもの
* …他にあれば追記する

----

NetHack 5.0 の詳細については、[README](README) または [README.JP](README.JP) を参照してください。

