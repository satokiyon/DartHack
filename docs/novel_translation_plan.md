<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` novel項目（Discworld小説リスト）日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` の最後尾に含まれる `novel` キー（Sir Terry Pratchett 氏の「Discworld」小説リスト）について、既訳の邦題を最大限尊重しつつ、未訳のものについては作中のテーマに合わせた自然な邦題風の日本語に翻訳します。

### 翻訳基本ルール:
*   **インデントとスペース**: 原文のコメントにある通り、tty画面でのフルスクリーン表示時の見た目を良くするため、行頭のTAB文字および余白スペース（例：`\t  ` や `\t    `）の構造を厳密に維持します。
*   **既訳邦題の採用**: 安田均氏の翻訳による角川文庫版のタイトル、およびあすなろ書房などの児童書レーベルの邦題があるものは、それをそのまま採用します。
*   **未訳タイトルの日本語化**: カタカナの音写に頼らず、ファンタジー小説の邦題として自然な日本語訳（例：`The Last Continent` -> 『最後の宿命大陸』）をあてます。
*   **誤変換の防止**: 助詞の「の」が `of` に誤変換されるバグ等が入らないよう、適用時に細心の注意を払い、`git diff` で徹底的に検証します。

---

## 2. 作業計画と進捗管理
本項目は一括で安全に適用・検証を行います。

### 進捗状況
- [x] **`novel` 項目の一括適用と検証** (1/1 完了)
  - [x] `novel` 以下の全リストを日本語翻訳に置換
  - [x] 適用後の `git diff` による差分確認（`of` 誤字およびインデント構造チェック）
  - [x] `makedefs -d` によるビルド検証とステージング (`git add`)

---

## 3. 詳細翻訳設計案（新訳案）

### 6164-6209行目付近
*   **原文**:
    ```text
    novel
    paperback book
    discworld novel*
    	  Discworld novel titles
    	    by Sir Terry Pratchett
    	  The Colour of Magic
    	  The Light Fantastic
    	  Equal Rites
    	  Mort
    	  Sourcery
    	  Wyrd Sisters
    	  Pyramids
    	  Guards! Guards!
    	  Eric
    	  Moving Pictures
    	  Reaper Man
    	  Witches Abroad
    	  Small Gods
    	  Lords and Ladies
    	  Men at Arms
    	  Soul Music
    	  Interesting Times
    	  Maskerade
    	  Feet of Clay
    	  Hogfather
    	  Jingo
    	  The Last Continent
    	  Carpe Jugulum
    	  The Fifth Elephant
    	  The Truth
    	  Thief of Time
    	  The Last Hero
    	  The Amazing Maurice and His Educated Rodents
    	  Night Watch
    	  The Wee Free Men
    	  Monstrous Regiment
    	  A Hat Full of Sky
    	  Going Postal
    	  Thud!
    	  Wintersmith
    	  Making Money
    	  Unseen Academicals
    	  I Shall Wear Midnight
    	  Snuff
    	  Raising Steam
    	  The Shepherd's Crown
    ```
*   **新訳案（インデント構造維持）**:
    ```text
    novel
    paperback book
    discworld novel*
    	  ディスクワールド小説一覧
    	    サー・テリー・プラチェット 著
    	  魔法の色彩
    	  奇天烈な光
    	  男女平等の儀式
    	  死神の徒弟
    	  ソーサリー
    	  三人の魔女
    	  ピラミッド
    	  衛兵！衛兵！
    	  エリック
    	  ムービング・ピクチャーズ
    	  死神と刈り入れ人
    	  旅する魔女たち
    	  小さな神々
    	  妖精王と女王
    	  男たち、武器を取れ
    	  ソウル・ミュージック
    	  面白い時代
    	  仮面劇
    	  粘土の足
    	  ホグファザー
    	  狂信的愛国主義
    	  最後の宿命大陸
    	  喉首を掻き切れ
    	  第５のゾウ
    	  真実
    	  時の盗賊
    	  最後の英雄
    	  天才猫モーリスとその仲間たち
    	  夜警
    	  ちっちゃな自由人
    	  怪物連隊
    	  空いっぱいの帽子
    	  郵便事業、始めました
    	  サッド！
    	  冬の鍛冶屋
    	  株と金と郵便局
    	  見えざる大学のフットボール
    	  真夜中を身にまとって
    	  スナッフ
    	  蒸気を上げろ
    	  羊飼いの王冠
    ```

---

## 4. 検証プロセス
1. **ピンポイント置換**: 翻訳箇所を手動で丁寧に置換。
2. **差分目視確認**: `git diff` により差分を徹底確認。助詞「の」が `of` になっていないこと、インデント崩れがないことを1文字単位でチェック。
3. **ビルドテスト**: `dat/` ディレクトリで `..\tools\Debug\x64\makedefs.exe -d` を実行し、Exit Code 0 で正常終了し、`dat/data_jp` が正しく再構築されることを確認。
4. **ステージング**: 検証完了後、`git add dat/data_jp.base` を実行し保護。
