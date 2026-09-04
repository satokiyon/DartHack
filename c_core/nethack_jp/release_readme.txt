NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-02.
NetHack JP README


参考 : https://nethack.org/v500/ports/download-win.html

----

# Windows版 NetHack起動手順

1. ダウンロードしたzipファイルをすべて展開してください。
   (zipファイルの中にある状態で実行ファイルを起動しないでください)


2. 次のどちらかのファイルを起動してください。

   - NetHack.exe  (コンソール版)

   - NetHackW.exe (GUI版)


3. 必要であれば、ご自身の環境に合わせてNetHackの設定ファイルを編集してください。
   NetHackに関連するフォルダの場所と名前は、次のコマンドで確認できます。
   
     NetHack.exe --showpath

   設定は「.nethackrc」を編集してください。一度NetHackを起動すると
   nethackrc.template からコピーして自動作成されます。
   作成された %USERPROFILE%\NetHackJP\.nethackrc を編集してください。

----

# Linux版 NetHack起動手順

1. ダウンロードしたzipファイルをすべて展開してください。
   
     unzip NetHackJP-5.0.0-*-linux.zip


2. 展開されたディレクトリに移動し、必要に応じて実行権限が付与されているか確認してください。

     cd NetHackJP-5.0.0-*-linux
     chmod +x nethack nethackW nethack.bin


3. 次のどちらかのスクリプトを起動してください。

   - ./nethack   (コンソール版 TTY / ncurses インターフェース)

   - ./nethackW  (GUI版 X11 インターフェース - 黒背景・白文字表示)

   ※ X11 GUI版のタイルセットはファイル名が「x11tiles」固定となっており、タイルの画像サイズは自動判定されます。
   ※ GUI使用時に日本語や墓石の死因が文字化け（豆腐文字表示）する場合は、環境に日本語 CJK フォント（Noto Sans CJK JP 等）をインストールしてください（例: sudo apt install -y fonts-noto-cjk）。


4. 必要であれば、ご自身の環境に合わせてNetHackの設定ファイルを編集してください。
   NetHackに関連するフォルダの場所と名前は、次のコマンドで確認できます。

     ./nethack --showpath

   設定は「.nethackrc」を編集してください。一度NetHackを起動すると
   nethackrc.template からコピーして自動作成されます。
   作成された $HOME/.nethackrc を編集してください。

----
     
設定ファイルに指定できるオプションや、ゲーム内容に関する説明は、Guidebook_JP.txtを参照してください。

Android版をプレイしたい場合はGoogle PlayのDartHackのページ( https://play.google.com/store/apps/details?id=jp.satokiyo.darthack )からインストールしてください。
