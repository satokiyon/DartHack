# Modified by NetHackJP contributor @satokiyon; latest change date: 2026-10-24.
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_markdown_guidebook.py

Guidebook.txt (英語原本) または Guidebook_JP.txt (日本語原本) を読み込み、
スマートフォンやWebで読みやすい Markdown ファイル (Guidebook.md / Guidebook_JP.md) を生成します。

機能:
1. roff 引用符 (`... ' や ``') を Markdown インラインコード (`...` や `` ` ``) へ自動置換。
2. アスキーアート（図1、図2、図3）を WebP 画像リンクへ置換し、<details> 折りたたみでテキスト版AAを併記。
3. 横幅の広いテキストブロック（7.5 防具AC表、9.15 記号表、12.2 ダンジョニア一覧）を Markdown 表形式（テーブル）に変換。
4. #extended_command をリスト項目 (- `#command` : ...) として整形し、見出し誤認を防止。
5. 9.5 以降のオプション名・特殊キー名をリスト項目 (- **option**) として構造化。
6. 設定例・構文例 (OPTIONS=..., BIND=..., MSGTYPE=..., autopickup_exception=... 等) をコードブロック (```text) に整形。

使用方法:
  python docs/scripts/build_markdown_guidebook.py          # 日英両方を生成
  python docs/scripts/build_markdown_guidebook.py --lang jp # 日本語のみ生成
  python docs/scripts/build_markdown_guidebook.py --lang en # 英語のみ生成
"""

import sys
import os
import re
import argparse

def is_page_header_or_footer(line):
    """改ページヘッダー・フッター行を検出"""
    s = line.strip()
    if not s:
        return False
    if re.match(r'^NetHack\s+5\.\d+\.\d+\s+.*?\d{4}$', s):
        return True
    if re.match(r'^NetHack\s+Guidebook\s+\d+$', s):
        return True
    return False

def clean_input_lines(lines):
    """改ページヘッダー・フッターを除去し、過剰な空行を圧縮"""
    cleaned = []
    skip_mode = False
    
    for line in lines:
        raw = line.rstrip('\r\n')
        s = raw.strip()
        
        if is_page_header_or_footer(s):
            skip_mode = True
            continue
        
        if skip_mode:
            if not s:
                continue
            else:
                skip_mode = False
        
        cleaned.append(raw)
    return cleaned

def convert_roff_quotes(text):
    """
    roff 引用符 (`...' や ``') を Markdown のインラインコード構文へ変換する
    """
    if not text:
        return ""
    
    # 0. 原本誤植: ``a' または ``a` -> `` ` `` (アーティファクト一覧の ` コマンド)
    text = re.sub(r"``a['`]", r"`` ` ``", text)
    
    # 1. バッククォート文字自身の引用: ``' または ``` -> `` ` ``
    text = re.sub(r"``'", r"`` ` ``", text)
    text = re.sub(r"(?<!`)```(?!`)", r"`` ` ``", text)
    
    # 2. バックスラッシュ記号自体の引用: `\`' または `\'` -> `\`
    text = re.sub(r"`\\`?'", r"`\\`", text)
    
    # 3. シングルクォート記号自体の引用: `\'' -> `'`
    text = text.replace("`\''", "`'`")
    
    # 4. roff の二重引用符: ``word'' -> "word"
    text = re.sub(r"``([^`'\r\n]+?)''", r'"\1"', text)
    
    # 5. 日本語版の鉤括弧内のバッククォート: 「`」 -> 「`` ` ``」
    text = text.replace('「`」', '「`` ` ``」')
    
    # 6. invorder オプション値内のバッククォートエスケープ
    text = text.replace('")[%?+!=/(*`0_"', '") `` [%?+!=/(*`0_"] ``')
    text = text.replace('")[%?+!=/(*`0_")', '") `` [%?+!=/(*`0_"] ``')
    text = text.replace('")[%?+!=/(*`0_"]"', '") `` [%?+!=/(*`0_"] ``"')
    
    # 7. 一般の roff 一重引用符: `word' -> `word` (1〜60文字に制限してアポストロフィ誤マッチを防止)
    text = re.sub(r"`([^`'\r\n]{1,60})'", r"`\1`", text)
    
    return text

def join_para(lines, lang="jp"):
    """パラグラフの行を自然に結合"""
    if not lines:
        return ""
    if lang == "en":
        # 英語: 単語間ハイフネーションを結合し、半角スペースで連結
        text = " ".join([l.strip() for l in lines if l.strip()])
        # ハイフンでの改行結合 (例: protec- tion -> protection)
        text = re.sub(r'(\b[a-zA-Z]+)-\s+([a-zA-Z]+\b)', r'\1\2', text)
        return convert_roff_quotes(text)
    else:
        # 日本語: 全角文字間のスペースを除去
        text = " ".join([l.strip() for l in lines if l.strip()])
        text = re.sub(r'([ぁ-んァ-ヶ亜-瑤])\s+([ぁ-んァ-ヶ亜-瑤])', r'\1\2', text)
        text = re.sub(r'([ぁ-んァ-ヶ亜-瑤])\s+([、。，．！？])', r'\1\2', text)
        text = re.sub(r'([、。，．！？])\s+([ぁ-んァ-ヶ亜-瑤])', r'\1\2', text)
        return convert_roff_quotes(text)

def parse_guidebook(src_path, dst_path, lang="jp"):
    print(f"Processing {src_path} -> {dst_path} (lang={lang})...")
    with open(src_path, 'r', encoding='utf-8') as f:
        raw_lines = f.readlines()

    lines = clean_input_lines(raw_lines)
    n = len(lines)
    out = []

    # ドキュメントタイトル
    if lang == "jp":
        out.append("# NetHack 5.0 ガイドブック (NetHack Guidebook)\n\n")
    else:
        out.append("# A Guide to the Mazes of Menace (Guidebook)\n\n")

    i = 0
    in_sec2_roles = False
    in_sec3_1_status = False
    in_sec9_options = False
    in_sec9_5_options = False
    in_sec9_6_options = False
    in_sec9_7_options = False
    in_sec9_10_keys = False
    in_sec9_17_blind = False
    in_sec9_18_sysconf = False

    current_para = []

    def flush_para():
        nonlocal current_para
        if current_para:
            text = join_para(current_para, lang)
            if text:
                out.append(text + "\n\n")
            current_para = []

    while i < n:
        line = lines[i]
        s = line.strip()

        # 1. 空行の処理
        if not s:
            flush_para()
            i += 1
            continue

        # 2. セクション見出しの判定
        m_sec = re.match(r'^(?:     )?([1-9]\d*(?:\.\d+)*)\.?\s+(.+)$', line)
        if m_sec:
            num = m_sec.group(1)
            title = m_sec.group(2).strip()
            
            # 見出し誤判定の除外
            if not (len(title) > 80 or title.startswith(('is', 'are', 'was', 'were', 'for', 'to', 'that', 'with', 'の', 'は', 'が', 'を', 'に'))):
                flush_para()
                dots = num.count('.')
                if dots == 0:
                    hashes = "##"
                elif dots == 1:
                    hashes = "###"
                else:
                    hashes = "####"
                
                clean_title = convert_roff_quotes(title)
                out.append(f"{hashes} {num} {clean_title}\n\n")

                in_sec2_roles = (num == "2")
                in_sec3_1_status = (num == "3.1")
                in_sec9_options = (num == "9.4")
                in_sec9_5_options = (num == "9.5")
                in_sec9_6_options = (num == "9.6")
                in_sec9_7_options = (num == "9.7")
                in_sec9_10_keys = (num == "9.10")
                in_sec9_17_blind = (num == "9.17")
                in_sec9_18_sysconf = (num == "9.18")

                i += 1
                continue

        # 3. 図1のアスキーアート（画面レイアウト）
        if "+-------" in line and any("The bat bites!" in lines[k] for k in range(i, min(i+5, n))):
            flush_para()
            aa_lines = [lines[i].strip()]
            i += 1
            while i < n:
                aa_lines.append(lines[i].strip())
                if "+-------" in lines[i] and len(aa_lines) >= 3:
                    i += 1
                    break
                i += 1
            
            fig_title = "図1: 画面レイアウトサンプル" if lang == "jp" else "Figure 1: Screen Layout Sample"
            summary_text = "テキスト版（アスキーアート）を表示" if lang == "jp" else "Show text version (ASCII art)"
            out.append(f"![{fig_title}](images/fig1.webp)\n\n")
            out.append(f"<details>\n<summary>{summary_text}</summary>\n\n```text\n")
            out.extend([l + "\n" for l in aa_lines])
            out.append("```\n</details>\n\n")
            continue

        # 4. 図2のアスキーアート（ステータス行）
        if "+-------" in line and any("Player the Rambler" in lines[k] or "Dlvl:1" in lines[k] for k in range(i, min(i+5, n))):
            flush_para()
            aa_lines = [lines[i].strip()]
            i += 1
            while i < n:
                aa_lines.append(lines[i].strip())
                if "+-------" in lines[i] and len(aa_lines) >= 3:
                    i += 1
                    break
                i += 1
            
            fig_title = "図2: ステータス行レイアウト" if lang == "jp" else "Figure 2: Status Lines Layout"
            summary_text = "テキスト版（アスキーアート）を表示" if lang == "jp" else "Show text version (ASCII art)"
            out.append(f"![{fig_title}](images/fig2.webp)\n\n")
            out.append(f"<details>\n<summary>{summary_text}</summary>\n\n```text\n")
            out.extend([l + "\n" for l in aa_lines])
            out.append("```\n</details>\n\n")
            continue

        # 5. 図3のアスキーアート（移動キー配置図）
        if "+-------" in line and any(("y  k  u" in lines[k] or "Figure-3" in lines[k] or "図3" in lines[k]) for k in range(i, min(i+15, n))):
            flush_para()
            while i < n:
                if "+-------" in lines[i] and ("Figure-3" in lines[i] or "図3" in lines[i]):
                    i += 1
                    break
                i += 1
            
            fig_title = "図3: 移動キー配置ダイアグラム" if lang == "jp" else "Figure 3: Movement Keys Diagram"
            summary_text = "テキスト版（アスキーアート）を表示" if lang == "jp" else "Show text version (ASCII art)"
            out.append(f"![{fig_title}](images/fig3.webp)\n\n")
            out.append(f"<details>\n<summary>{summary_text}</summary>\n\n```text\n")
            if lang == "jp":
                fig3_aa = """+------------------------------------------+
|     y  k  u                7  8  9       |
|      \\ | /                  \\ | /        |
|     h- . -l                4- . -6       |
|      / | \\                  / | \\        |
|     b  j  n                1  2  3       |
| (number_pad オフ)     (number_pad オン)  |
+-------------------図3--------------------+"""
            else:
                fig3_aa = """+------------------------------------------+
|     y  k  u                7  8  9       |
|      \\ | /                  \\ | /        |
|     h- . -l                4- . -6       |
|      / | \\                  / | \\        |
|     b  j  n                1  2  3       |
| (number_pad off)      (number_pad on)    |
+-----------------Figure-3-----------------+"""
            out.append(fig3_aa + "\n```\n</details>\n\n")
            continue

        # 6. セクション 7.5: 防具AC表のテーブル化
        if ("ドラゴン・スケイル・メイル" in line and "1" in line) or ("Dragon scale mail" in line and "1" in line):
            flush_para()
            armor_lines = []
            while i < n:
                if not lines[i].strip():
                    if i + 1 < n and not lines[i+1].strip():
                        i += 1
                        break
                    if i + 1 < n and any(kw in lines[i+1] for kw in ["盾", "クローク", "ヘルメット", "手袋", "ブーツ", "shield", "cloak", "helmet", "boots"]):
                        i += 1
                        break
                    armor_lines.append(lines[i])
                    i += 1
                    continue
                if any(kw in lines[i] for kw in ["盾", "クローク", "ヘルメット", "手袋", "ブーツ", "shield", "cloak", "helmet", "boots"]):
                    break
                armor_lines.append(lines[i])
                i += 1
            
            # テーブルヘッダー
            if lang == "jp":
                out.append("| 鎧（防具） | AC値 |\n|:---|:---:|\n")
            else:
                out.append("| Suit of Armor | AC |\n|:---|:---:|\n")
            
            cur_armor_name = []
            for al in armor_lines:
                als = al.strip()
                if not als:
                    continue
                m_ac = re.search(r'^(.*?)\s+(\d+)$', als)
                if m_ac:
                    cur_armor_name.append(m_ac.group(1).strip())
                    name = convert_roff_quotes(" ".join(cur_armor_name))
                    ac = m_ac.group(2)
                    out.append(f"| {name} | {ac} |\n")
                    cur_armor_name = []
                else:
                    cur_armor_name.append(als)
            out.append("\n")
            continue

        # 7. セクション 9.15: 記号表のテーブル化
        if "-----------------------------------------------------------------" in line and i > 0 and ("S_air" in lines[i+1] if i+1 < n else False):
            flush_para()
            i += 1  # 境界線をスキップ
            sym_lines = []
            while i < n:
                if not lines[i].strip():
                    if i + 1 < n and (lines[i+1].startswith("     9.16") or lines[i+1].startswith("     10.") or "Customizing Map Glyph" in lines[i+1] or "Unicode" in lines[i+1]):
                        break
                    sym_lines.append(lines[i])
                    i += 1
                    continue
                if lines[i].startswith("     9.16") or lines[i].startswith("     10.") or "Customizing Map Glyph" in lines[i] or "Unicode" in lines[i]:
                    break
                sym_lines.append(lines[i])
                i += 1
            
            if lang == "jp":
                out.append("| 記号 | 記号名 | 説明 |\n|:---:|:---|:---|\n")
            else:
                out.append("| NetHack Symbol | Symbol Name | Description |\n|:---:|:---|:---|\n")

            for sl in sym_lines:
                sls = sl.rstrip()
                if not sls.strip():
                    continue
                m_sym = re.match(r'^\s*([^\s]{1,2})?\s+(S_[a-zA-Z0-9_]+)\s+(.*)$', sls)
                if m_sym:
                    sym = m_sym.group(1) or ""
                    sname = m_sym.group(2)
                    desc = convert_roff_quotes(m_sym.group(3).strip())
                    if desc.startswith("(") and desc.endswith(")"):
                        desc = desc[1:-1]
                    if sym == "`":
                        sym_disp = "`` ` ``"
                    elif sym:
                        sym_disp = f"`{sym}`"
                    else:
                        sym_disp = ""
                    out.append(f"| {sym_disp} | `{sname}` | {desc} |\n")
                else:
                    m_sname_only = re.match(r'^\s*(S_[a-zA-Z0-9_]+)\s+(.*)$', sls)
                    if m_sname_only:
                        sname = m_sname_only.group(1)
                        desc = convert_roff_quotes(m_sname_only.group(2).strip())
                        if desc.startswith("(") and desc.endswith(")"):
                            desc = desc[1:-1]
                        out.append(f"|  | `{sname}` | {desc} |\n")
            out.append("\n")
            continue

        # 8. セクション 12.2: ダンジョニア一覧のテーブル化
        if "Adam Aronow" in line and ("Irina Rempt-Drijfhout" in line or "Izchak Miller" in line or i+1 < n):
            flush_para()
            dung_lines = []
            while i < n:
                if not lines[i].strip():
                    if i + 1 < n and (lines[i+1].startswith("     12.3") or lines[i+1].startswith("     13.") or "13." in lines[i+1]):
                        break
                    dung_lines.append(lines[i])
                    i += 1
                    continue
                if lines[i].startswith("     12.3") or lines[i].startswith("     13.") or "13." in lines[i]:
                    break
                dung_lines.append(lines[i])
                i += 1
            
            col_name = "ダンジョニア" if lang == "jp" else "Dungeoneer"
            out.append(f"| {col_name} | {col_name} | {col_name} |\n|:---|:---|:---|\n")

            for dl in dung_lines:
                dls = dl.rstrip()
                if not dls.strip():
                    continue
                col1 = dls[0:25].strip() if len(dls) >= 25 else dls.strip()
                col2 = dls[25:53].strip() if len(dls) >= 53 else (dls[25:].strip() if len(dls) > 25 else "")
                col3 = dls[53:].strip() if len(dls) > 53 else ""
                
                if col1 or col2 or col3:
                    out.append(f"| {col1} | {col2} | {col3} |\n")
            out.append("\n")
            continue

        # 8.5 セクション 2 職業および種族のリスト化
        if in_sec2_roles:
            m_role_jp = re.match(r'^\s*(考古学者|蛮族|洞窟人|治療師|騎士|武闘家|司祭|レンジャー|盗賊|侍|観光客|ワルキューレ|魔法使い|ドワーフ|エルフ|ノーム|人間|オーク)（([^）]+)）(?:は|、|\s)(.*)$', line)
            if m_role_jp:
                flush_para()
                jp_name = m_role_jp.group(1)
                en_name = m_role_jp.group(2)
                rest = m_role_jp.group(3).strip()
                if rest.startswith(('は、', 'は ', 'は')):
                    rest = re.sub(r'^は[、\s]?', '', rest)
                role_lines = [rest] if rest else []
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    role_lines.append(lines[i].strip())
                    i += 1
                desc = join_para(role_lines, lang="jp")
                out.append(f"- **{jp_name}（{en_name}）** : {desc}\n")
                continue

            m_role_en = re.match(r'^\s*(Archeologists?|Barbarians?|Cavem[ae]n(?: and Cavewomen)?|Healers?|Knights?|Monks?|Priests?(?: and Priestesses)?|Rangers?|Rogues?|Samurai|Tourists?|Valkyries?|Wizards?|Dwarves|Elves|Gnomes|Humans?|Orcs)\b(?:\s+(.*))?$', line)
            if m_role_en:
                flush_para()
                raw_name = m_role_en.group(1).strip()
                rest = m_role_en.group(2).strip() if m_role_en.group(2) else ""
                role_map = {
                    "Archeologists": "Archeologist", "Barbarians": "Barbarian",
                    "Cavemen and Cavewomen": "Caveman / Cavewoman", "Healers": "Healer",
                    "Knights": "Knight", "Monks": "Monk",
                    "Priests and Priestesses": "Priest / Priestess", "Rangers": "Ranger",
                    "Rogues": "Rogue", "Samurai": "Samurai", "Tourists": "Tourist",
                    "Valkyries": "Valkyrie", "Wizards": "Wizard",
                    "Dwarves": "Dwarf", "Elves": "Elf", "Gnomes": "Gnome",
                    "Humans": "Human", "Orcs": "Orc"
                }
                role_label = role_map.get(raw_name, raw_name)
                role_lines = [rest] if rest else []
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    role_lines.append(lines[i].strip())
                    i += 1
                desc = join_para(role_lines, lang="en")
                out.append(f"- **{role_label}** : {desc}\n")
                continue

        # 8.6 セクション 3.1 ステータス項目のリスト化
        if in_sec3_1_status:
            # 状態（Status）の親項目判定
            if line.strip() in ("状態（Status）", "Status"):
                flush_para()
                label = "状態（Status）" if lang == "jp" else "Status"
                out.append(f"- **{label}** :\n")
                i += 1
                continue

            # 状態（Status）のサブ項目判定（日本語）
            m_sub_jp = re.match(r'^\s*(空腹度|荷重|致命的な状態|致命的でない状態|移動修正)（([^）]+)）:\s*(.*)$', line)
            if m_sub_jp:
                flush_para()
                sub_jp = m_sub_jp.group(1)
                sub_en = m_sub_jp.group(2)
                sub_rest = m_sub_jp.group(3).strip()
                sub_lines = [sub_rest] if sub_rest else []
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    if re.match(r'^\s*(?:空腹度|荷重|致命的な状態|致命的でない状態|移動修正)（', lines[i]):
                        break
                    sub_lines.append(lines[i].strip())
                    i += 1
                sub_desc = join_para(sub_lines, lang="jp")
                out.append(f"  - **{sub_jp}（{sub_en}）** : {sub_desc}\n")
                continue

            # 状態（Status）のサブ項目判定（英語）
            m_sub_en = re.match(r'^\s*(Hunger|Encumbrance|Fatal conditions|Non-fatal conditions|Movement modifiers):\s*(.*)$', line)
            if m_sub_en:
                flush_para()
                sub_label = m_sub_en.group(1).strip()
                sub_rest = m_sub_en.group(2).strip()
                sub_lines = [sub_rest] if sub_rest else []
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    if re.match(r'^\s*(?:Hunger|Encumbrance|Fatal conditions|Non-fatal conditions|Movement modifiers):', lines[i]):
                        break
                    sub_lines.append(lines[i].strip())
                    i += 1
                sub_desc = join_para(sub_lines, lang="en")
                out.append(f"  - **{sub_label}** : {sub_desc}\n")
                continue

            # 一般ステータス項目（日本語）
            m_stat_jp = re.match(r'^\s*(名前|筋力|器用さ|耐久力|知力|賢明さ|魅力|属性|ダンジョン階層|ゴールド|ヒットポイント|魔力|アーマークラス|経験|時間)（([^）]+)）(?:\s+(.*))?$', line)
            if m_stat_jp:
                flush_para()
                stat_jp = m_stat_jp.group(1)
                stat_en = m_stat_jp.group(2)
                stat_rest = m_stat_jp.group(3).strip() if m_stat_jp.group(3) else ""
                stat_lines = [stat_rest] if stat_rest else []
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    stat_lines.append(lines[i].strip())
                    i += 1
                stat_desc = join_para(stat_lines, lang="jp")
                out.append(f"- **{stat_jp}（{stat_en}）** : {stat_desc}\n")
                continue

            # 一般ステータス項目（英語）
            m_stat_en = re.match(r'^\s*(Title|Strength|Dexterity|Constitution|Intelligence|Wisdom|Charisma|Alignment|Dungeon Level|Gold|Hit Points|Power|Armor Class|Experience|Time)(?:\s+(.*))?$', line)
            if m_stat_en and not line.strip().startswith(('Title:', 'Strength:', 'Status lines')):
                flush_para()
                stat_label = m_stat_en.group(1)
                stat_rest = m_stat_en.group(2).strip() if m_stat_en.group(2) else ""
                stat_lines = [stat_rest] if stat_rest else []
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    stat_lines.append(lines[i].strip())
                    i += 1
                stat_desc = join_para(stat_lines, lang="en")
                out.append(f"- **{stat_label}** : {stat_desc}\n")
                continue

            # #attributes コマンドの整形
            if "#attributes" in line:
                flush_para()
                attr_lines = [line.strip()]
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    attr_lines.append(lines[i].strip())
                    i += 1
                attr_desc = join_para(attr_lines, lang)
                attr_desc = attr_desc.replace("#attributes", "`#attributes`")
                attr_desc = attr_desc.replace("^X", "`^X`")
                out.append(f"{attr_desc}\n\n")
                continue

        # 9. コードブロックの整形（設定例、コマンド構文、定義）
        m_code_start = (
            re.match(r'^\s*(autopickup_exception="[^"]*")', line) or
            re.match(r'^\s*(BIND=\S+)', line) or
            re.match(r'^\s*(MSGTYPE=(?:hide|stop|norepick|show)\b)', line) or
            re.match(r'^\s*(MENUCOLOR="[^"]*")', line) or
            re.match(r'^\s*(SOUND=MESG\b)', line) or
            re.match(r'^\s*(SOUNDDIR=\S+)', line) or
            re.match(r'^\s*(OPTIONS=glyph:)', line) or
            re.match(r'^\s*(OPTIONS=role:)', line) or
            re.match(r'^\s*(OPTIONS?=hilite_status[:=])', line) or
            re.match(r'^\s*(OPTIONS=hilit_status\b)', line) or
            re.match(r'^\s*(WIZKIT=)', line) or
            re.match(r'^\s*(MENUCOLOR="pattern"=color)', line)
        )
        if m_code_start:
            flush_para()
            code_lines = []
            while i < n:
                if not lines[i].strip():
                    break
                code_lines.append(lines[i].strip())
                i += 1
            out.append("```text\n")
            for cl in code_lines:
                out.append(cl + "\n")
            out.append("```\n\n")
            continue

        # 10. 拡張コマンド (#command) リスト化 (単独行およびインライン説明、英語・日本語共通)
        m_hash_cmd = re.match(r'^(?:     )?(#[a-z0-9_]+)(?:\s+(.*))?$', line)
        if m_hash_cmd and not in_sec9_options and not in_sec9_5_options and not in_sec9_6_options and not in_sec9_7_options and not in_sec9_10_keys:
            flush_para()
            cmd_name = m_hash_cmd.group(1).strip()
            first_desc = m_hash_cmd.group(2)
            i += 1
            cmd_desc_lines = [first_desc.strip()] if first_desc and first_desc.strip() else []
            while i < n:
                if not lines[i].strip():
                    if i + 1 < n and (re.match(r'^(?:     )?#[a-z0-9_]+', lines[i+1]) or re.match(r'^\s*[1-9]\.', lines[i+1])):
                        i += 1
                        break
                    else:
                        cmd_desc_lines.append("\n\n")
                        i += 1
                        continue
                if re.match(r'^(?:     )?#[a-z0-9_]+', lines[i]) or re.match(r'^\s*[1-9]\.', lines[i]):
                    break
                cmd_desc_lines.append(lines[i].strip())
                i += 1
            
            paras = "".join(cmd_desc_lines).split("\n\n")
            clean_paras = [join_para([p], lang) for p in paras if p.strip()]
            if clean_paras:
                out.append(f"- `{cmd_name}` : {clean_paras[0]}\n\n")
                for cp in clean_paras[1:]:
                    out.append(f"  {cp}\n\n")
            else:
                out.append(f"- `{cmd_name}`\n\n")
            continue

        # 11. コマンドキー定義リスト: "- `key` : 説明"
        m_cmd = re.match(r'^(?:     )?([a-zA-Z0-9\?\/\<\>\,\.\;\:\'\"\[\]\{\}\\\|\`\~\!\@\$\%\^\&\*\(\)\_\+\-\=\#\^][a-zA-Z0-9\-\^\?]*)\s{2,}(.+)$', line)
        if m_cmd and not in_sec9_options and not in_sec9_5_options and not in_sec9_6_options and not in_sec9_7_options and not in_sec9_10_keys and not in_sec3_1_status and not in_sec2_roles:
            cmd_key = m_cmd.group(1).strip()
            first_desc = m_cmd.group(2).strip()
            
            # 見出し行や通常文の誤判定防止
            if not (len(cmd_key) > 15 or cmd_key in ["NetHack", "OPTIONS", "The", "For", "In", "When", "If", "However", "See", "This", "These"]):
                flush_para()
                cmd_desc_lines = [first_desc]
                i += 1
                while i < n:
                    if not lines[i].strip():
                        break
                    m_next_cmd = re.match(r'^(?:     )?([a-zA-Z0-9\?\/\<\>\,\.\;\:\'\"\[\]\{\}\\\|\`\~\!\@\$\%\^\&\*\(\)\_\+\-\=\#\^][a-zA-Z0-9\-\^\?]*)\s{2,}(.+)$', lines[i])
                    if m_next_cmd and not lines[i].startswith("       "):
                        break
                    cmd_desc_lines.append(lines[i].strip())
                    i += 1
                desc_text = join_para(cmd_desc_lines, lang)
                
                # バッククォートキー自体の表示
                if cmd_key == "`":
                    out.append(f"- `` ` `` : {desc_text}\n")
                else:
                    out.append(f"- `{cmd_key}` : {desc_text}\n")
                continue

        # 12. セクション 9.18 システム管理者向け設定 (sysconf): "- **PARAM**"
        if in_sec9_18_sysconf:
            m_sysconf = re.match(r'^\s*([A-Z][A-Z0-9_]+)\s*=\s*(.*)$', line)
            if m_sysconf:
                flush_para()
                param_name = m_sysconf.group(1).strip()
                first_desc = m_sysconf.group(2).strip()
                i += 1
                desc_lines = [first_desc] if first_desc else []
                while i < n:
                    if not lines[i].strip():
                        if i + 1 < n and (re.match(r'^\s*[A-Z][A-Z0-9_]+\s*=', lines[i+1]) or re.match(r'^\s*[1-9]\.', lines[i+1])):
                            i += 1
                            break
                        else:
                            desc_lines.append("\n\n")
                            i += 1
                            continue
                    if re.match(r'^\s*[A-Z][A-Z0-9_]+\s*=', lines[i]) or re.match(r'^\s*[1-9]\.', lines[i]):
                        break
                    desc_lines.append(lines[i].strip())
                    i += 1
                
                paras = "".join(desc_lines).split("\n\n")
                clean_paras = [join_para([p], lang) for p in paras if p.strip()]
                out.append(f"- **{param_name}**\n\n")
                for cp in clean_paras:
                    out.append(f"  {cp}\n\n")
                continue

        # 12. セクション 9.18 システム管理者向け設定 (sysconf): "- **PARAM**"
        if in_sec9_18_sysconf:
            m_sysconf = re.match(r'^\s*([A-Z][A-Z0-9_]+)\s*=\s*(.*)$', line)
            if m_sysconf:
                flush_para()
                param_name = m_sysconf.group(1).strip()
                first_desc = m_sysconf.group(2).strip()
                i += 1
                desc_lines = [first_desc] if first_desc else []
                while i < n:
                    if not lines[i].strip():
                        if i + 1 < n and (re.match(r'^\s*[A-Z][A-Z0-9_]+\s*=', lines[i+1]) or re.match(r'^\s*[1-9]\.', lines[i+1])):
                            i += 1
                            break
                        else:
                            desc_lines.append("\n\n")
                            i += 1
                            continue
                    if re.match(r'^\s*[A-Z][A-Z0-9_]+\s*=', lines[i]) or re.match(r'^\s*[1-9]\.', lines[i]):
                        break
                    desc_lines.append(lines[i].strip())
                    i += 1
                
                paras = "".join(desc_lines).split("\n\n")
                clean_paras = [join_para([p], lang) for p in paras if p.strip()]
                out.append(f"- **{param_name}**\n\n")
                for cp in clean_paras:
                    out.append(f"  {cp}\n\n")
                continue

        # 13. セクション 9.4, 9.5, 9.6, 9.7, 9.10, 9.17 オプション一覧: "- **opt** ..."
        if in_sec9_options or in_sec9_5_options or in_sec9_6_options or in_sec9_7_options or in_sec9_10_keys or in_sec9_17_blind:
            # 9.6 OPTION=crash_...
            m_opt_crash = re.match(r'^\s*OPTION=(crash_\w+:\w+)\s*$', line)
            if m_opt_crash:
                flush_para()
                opt_name = m_opt_crash.group(1)
                i += 1
                temp_i = i
                while temp_i < n and not lines[temp_i].strip():
                    temp_i += 1
                if temp_i < n and re.match(r'^\s*OPTION=(crash_\w+:\w+)\s*$', lines[temp_i]):
                    out.append(f"- **{opt_name}**\n")
                    i = temp_i
                    continue

                opt_desc_lines = []
                while i < n:
                    if not lines[i].strip():
                        if i + 1 < n and (re.match(r'^\s*OPTION=(crash_\w+:\w+)\s*$', lines[i+1]) or re.match(r'^\s*[1-9]\.', lines[i+1])):
                            i += 1
                            break
                        else:
                            opt_desc_lines.append("\n\n")
                            i += 1
                            continue
                    if re.match(r'^\s*OPTION=(crash_\w+:\w+)\s*$', lines[i]) or re.match(r'^\s*[1-9]\.', lines[i]):
                        break
                    opt_desc_lines.append(lines[i].strip())
                    i += 1
                opt_paras = "".join(opt_desc_lines).split("\n\n")
                clean_paras = [join_para([p], lang) for p in opt_paras if p.strip()]
                out.append(f"- **{opt_name}**\n\n")
                for cp in clean_paras:
                    out.append(f"  {cp}\n\n")
                continue

            # 9.4, 9.5, 9.7, 9.10 のオプション名・キー名
            m_opt = (re.match(r'^(?:     )?([a-z_][a-z0-9_\.:]*)$', line) or
                     re.match(r'^(?:     )?(BIOS|rawio|subkeyvalue|video)$', line))
            
            # 通常文の誤除外
            skip_starters = ('ここでは', '使用している', 'プログラム', '設定ファイル', '例：', '注意：', '例:', '以下',
                             'Here', 'These', 'This', 'The', 'For', 'Note', 'When', 'If', 'In', 'Some')
            if m_opt and not line.strip().startswith(skip_starters):
                flush_para()
                opt_name = m_opt.group(1).strip()
                i += 1
                opt_desc_lines = []
                while i < n:
                    if not lines[i].strip():
                        if i + 1 < n and (re.match(r'^(?:     )?([a-z_][a-z0-9_\.:]*)$', lines[i+1]) or
                                          re.match(r'^(?:     )?(BIOS|rawio|subkeyvalue|video)$', lines[i+1]) or
                                          re.match(r'^\s*[1-9]\.', lines[i+1])):
                            i += 1
                            break
                        else:
                            opt_desc_lines.append("\n\n")
                            i += 1
                            continue
                    
                    if (re.match(r'^(?:     )?([a-z_][a-z0-9_\.:]*)$', lines[i]) or
                        re.match(r'^(?:     )?(BIOS|rawio|subkeyvalue|video)$', lines[i]) or
                        re.match(r'^\s*[1-9]\.', lines[i])):
                        break
                    
                    opt_desc_lines.append(lines[i].strip())
                    i += 1
                
                opt_paras = "".join(opt_desc_lines).split("\n\n")
                clean_paras = [join_para([p], lang) for p in opt_paras if p.strip()]
                out.append(f"- **{opt_name}**\n\n")
                for cp in clean_paras:
                    out.append(f"  {cp}\n\n")
                continue

        # 13. 通常パラグラフの蓄積
        current_para.append(s)
        i += 1

    flush_para()

    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    with open(dst_path, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f"Generated successfully: {dst_path} ({len(out)} chunks)")

def main():
    parser = argparse.ArgumentParser(description="Guidebook Markdown Builder")
    parser.add_argument("--lang", choices=["jp", "en", "all"], default="all",
                        help="Language to build (default: all)")
    args = parser.parse_args()

    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    guidebook_dir = os.path.join(root_dir, "Guidebook")

    targets = []
    if args.lang in ["jp", "all"]:
        targets.append(("jp",
                        os.path.join(guidebook_dir, "Guidebook_JP.txt"),
                        os.path.join(guidebook_dir, "Guidebook_JP.md")))
    if args.lang in ["en", "all"]:
        targets.append(("en",
                        os.path.join(guidebook_dir, "Guidebook.txt"),
                        os.path.join(guidebook_dir, "Guidebook.md")))

    for lang, src, dst in targets:
        if not os.path.exists(src):
            print(f"Error: Source file not found: {src}", file=sys.stderr)
            sys.exit(1)
        parse_guidebook(src, dst, lang)

if __name__ == "__main__":
    main()
