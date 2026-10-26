#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
update_companion_jp.py: 日本語版スポイラー (companion.jp.md) を DartHack に整形・同期するスクリプト

NetHack Companion JP (nethack-companion-jp) の spoilers/companion.jp.md を
DartHack の AGENTS.md ルール51（パラグラフ単位の改行、アスキーアート・テーブル保護、WebP画像化）
に準拠して整形し、以下を自動更新します：
  1. sys/flutter/books/jp/companion.jp.md (原本)
  2. sys/flutter/assets/nethackdir/jp/companion.jp.md (実行時アセット)
  3. sys/flutter/assets/ver (バージョンインクリメント)
"""

import argparse
import os
import re
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FLUTTER_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '..'))
DARTHACK_ROOT = os.path.abspath(os.path.join(FLUTTER_ROOT, '../..'))

DEFAULT_JP_SOURCES = [
    os.path.abspath(os.path.join(DARTHACK_ROOT, '../nethack-companion-jp/spoilers/companion.jp.md')),
    os.path.abspath(os.path.join(DARTHACK_ROOT, 'nethack-companion-jp/spoilers/companion.jp.md')),
]

TARGET_BOOKS = os.path.join(FLUTTER_ROOT, 'books/jp/companion.jp.md')
TARGET_ASSETS = os.path.join(FLUTTER_ROOT, 'assets/nethackdir/jp/companion.jp.md')
VER_FILE = os.path.join(FLUTTER_ROOT, 'assets/ver')


def find_default_source():
    for p in DEFAULT_JP_SOURCES:
        if os.path.isfile(p):
            return p
    return None


def slugify(text: str) -> str:
    # 括弧内の英語表記があれば優先抽出: 例 "ノームの鉱山 (The Gnomish Mines)" -> "The Gnomish Mines"
    en_paren_match = re.search(r'\(([A-Za-z0-9\s`_-]+)\)', text)
    if en_paren_match and re.search(r'[A-Za-z]', en_paren_match.group(1)):
        text = en_paren_match.group(1)

    t = re.sub(r'`([^`]+)`', r'\1', text)
    t = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', t)
    t = re.sub(r'[*_~]', '', t)
    t = re.sub(r'[^a-zA-Z0-9\s-]', '', t).strip().lower()
    t = re.sub(r'[\s_]+', '-', t)
    t = re.sub(r'-+', '-', t)
    return t


def format_markdown(content: str) -> str:
    # 1. 改行コードの統一 (\r\n -> \n)
    content = content.replace('\r\n', '\n')

    # 2. 冒頭の raw html タイトル・名言をイタリックに変換
    title_pattern = r'```{=html}\s*<p style="text-align: center; font-size: 1.25em; margin: 0.2em 0 1.4em;">(.*?)</p>\s*```'
    def replace_sub_title(m):
        raw = m.group(1)
        clean = re.sub(r'<[^>]+>', '', raw)
        return f"*{clean}*"
    content = re.sub(title_pattern, replace_sub_title, content, flags=re.DOTALL)

    quote_pattern = r'```{=html}\s*<p style="text-align: center; font-style: italic; margin: 1.5em 0;">(.*?)</p>\s*```'
    def replace_quote(m):
        raw = m.group(1)
        clean = re.sub(r'<[^>]+>', '', raw)
        return f"*{clean}*"
    content = re.sub(quote_pattern, replace_quote, content, flags=re.DOTALL)

    # 3. ガイドブック表記の同期（DartHackでは「脅威の迷宮へのガイド」）
    content = content.replace('脅威の迷宮案内記 (Guide to the Mazes of Menace)', '脅威の迷宮へのガイド (Guide to the Mazes of Menace)')

    # 4. DMAP ブロックを WebP 画像に置換
    dmap_pattern = r'<!-- DMAP-BEGIN -->.*?<!-- DMAP-END -->'
    dmap_replacement = '![支流は主幹の左右へと延びています。丸印はおおよそのフロア数を示します。★は3つの開扉のアイテムを示しています。](asset:assets/images/spoiler_dmap_jp.webp)'
    content = re.sub(dmap_pattern, dmap_replacement, content, flags=re.DOTALL)

    # 5. FLOWCHART ブロックを WebP 画像に置換
    flowchart_pattern = r'<!-- FLOWCHART-BEGIN -->.*?<!-- FLOWCHART-END -->(\s*```{=latex}.*?```)?'
    flowchart_replacement = '![識別のフローチャート：最も安価な方法から順に試し、識別の巻物は最後の手段とする。](asset:assets/images/spoiler_flowchart_jp.webp)'
    content = re.sub(flowchart_pattern, flowchart_replacement, content, flags=re.DOTALL)

    # 6. print-only ブロック（LaTeX索引など）の除去
    print_only_pattern = r':::\s*print-only.*?:::'
    content = re.sub(print_only_pattern, '', content, flags=re.DOTALL)

    # 7. その他の ```{=latex} ... ``` ブロックの除去
    latex_block_pattern = r'```{=latex}.*?```'
    content = re.sub(latex_block_pattern, '', content, flags=re.DOTALL)

    # 8. その他の ```{=html} ... ``` ブロックの除去
    html_block_pattern = r'```{=html}.*?```'
    content = re.sub(html_block_pattern, '', content, flags=re.DOTALL)

    # 9. 生の <script> ... </script> ブロックの除去（価格計算スクリプト等）
    script_pattern = r'<script\b[^>]*>.*?</script>'
    content = re.sub(script_pattern, '', content, flags=re.DOTALL | re.IGNORECASE)

    # 10. 生の価格識別ツールバー (<div class="price-id-toolbar"></div>) の除去
    toolbar_div_pattern = r'<div\s+class=["\']price-id-toolbar["\'][^>]*>\s*</div>'
    content = re.sub(toolbar_div_pattern, '', content, flags=re.IGNORECASE)

    # 11. <aside> ... </aside> の除去（PDFダウンロードリンク等）
    aside_pattern = r'<aside.*?</aside>'
    content = re.sub(aside_pattern, '', content, flags=re.DOTALL)

    # 12. <small>...</small> のタグ除去（注記テキストはイタリック化）
    content = re.sub(r'<small>(.*?)</small>', r'*\1*', content, flags=re.DOTALL | re.IGNORECASE)

    # 13. アプリ内では存在しないツールバー機能に言及した本文記述の除去
    toolbar_mention_pattern = r'[^\n]*魅力\s*/\s*売却\s*/\s*観光客\s*/\s*激怒ツールバーを使用して[^\n]*\n?'
    content = re.sub(toolbar_mention_pattern, '', content)

    # 14. インライン latex 構文の除去（例: `\newline`{=latex} や {=latex}）
    content = re.sub(r'<br>`\\newline`\{=latex\}', '', content)
    content = re.sub(r'`\\newline`\{=latex\}', '', content)
    content = re.sub(r'\{=latex\}', '', content)

    # 15. HTMLコメント <!-- ... --> の除去
    comment_pattern = r'<!--.*?-->'
    content = re.sub(comment_pattern, '', content, flags=re.DOTALL)

    # 16. Pandoc div 構文（::: dense-table, ::: web-only, ::: など）の除去
    lines = content.split('\n')
    filtered_lines = []
    for line in lines:
        if line.strip().startswith(':::') and not line.strip().startswith('::::'):
            continue
        if line.strip().startswith('::::'):
            continue
        filtered_lines.append(line)

    # 13. パラグラフ単位のソフトラップ整形
    out_lines = []
    in_code = False
    cur_paragraph = []

    def flush_paragraph():
        if cur_paragraph:
            merged = ""
            for idx, part in enumerate(cur_paragraph):
                part = part.strip()
                if not part:
                    continue
                if not merged:
                    merged = part
                else:
                    last_char = merged[-1]
                    first_char = part[0]
                    if (last_char.isalnum() or last_char in ".,;!?)]}") and (first_char.isalnum() or first_char in "([{$"):
                        merged += " " + part
                    else:
                        merged += part
            out_lines.append(merged)
            cur_paragraph.clear()

    i = 0
    while i < len(filtered_lines):
        line = filtered_lines[i]
        trimmed = line.strip()

        # コードブロック判定
        if trimmed.startswith('```'):
            flush_paragraph()
            in_code = not in_code
            out_lines.append(line)
            i += 1
            continue

        if in_code:
            out_lines.append(line)
            i += 1
            continue

        # 空行
        if not trimmed:
            flush_paragraph()
            if out_lines and out_lines[-1] != "":
                out_lines.append("")
            i += 1
            continue

        # 見出し
        if trimmed.startswith('#'):
            flush_paragraph()
            if out_lines and out_lines[-1] != "":
                out_lines.append("")
            heading_m = re.match(r'^(#{1,5})\s+(.+)$', trimmed)
            if heading_m:
                hashes = heading_m.group(1)
                title = heading_m.group(2).strip()
                if not re.search(r'\{#([a-zA-Z0-9_.-]+)[^}]*\}\s*$', title):
                    slug = slugify(title)
                    if slug:
                        trimmed = f"{hashes} {title} {{#{slug}}}"
            out_lines.append(trimmed)
            out_lines.append("")
            i += 1
            continue

        # 水平線
        if trimmed in ('---', '***', '___'):
            flush_paragraph()
            if out_lines and out_lines[-1] != "":
                out_lines.append("")
            out_lines.append(trimmed)
            out_lines.append("")
            i += 1
            continue

        # 画像
        if re.match(r'^!\[(.*?)\]\(.*?\)$', trimmed):
            flush_paragraph()
            if out_lines and out_lines[-1] != "":
                out_lines.append("")
            out_lines.append(trimmed)
            out_lines.append("")
            i += 1
            continue

        # テーブル判定
        if trimmed.startswith('|') and trimmed.endswith('|'):
            flush_paragraph()
            out_lines.append(trimmed)
            i += 1
            continue

        # リスト項目判定
        list_match = re.match(r'^(\s*([*\-+]|\d+\.)\s+)(.*)$', line)
        if list_match:
            flush_paragraph()
            prefix = list_match.group(1)
            item_text = [list_match.group(3).strip()]
            i += 1
            while i < len(filtered_lines):
                next_line = filtered_lines[i]
                next_trimmed = next_line.strip()
                if not next_trimmed:
                    break
                if next_trimmed.startswith('#') or next_trimmed.startswith('```') or next_trimmed.startswith('|') or next_trimmed in ('---', '***', '___'):
                    break
                if re.match(r'^\s*([*\-+]|\d+\.)\s+', next_line):
                    break
                item_text.append(next_trimmed)
                i += 1
            merged_item = ""
            for part in item_text:
                if not merged_item:
                    merged_item = part
                else:
                    last_c = merged_item[-1]
                    first_c = part[0]
                    if (last_c.isalnum() or last_c in ".,;!?)]}") and (first_c.isalnum() or first_c in "([{$"):
                        merged_item += " " + part
                    else:
                        merged_item += part
            out_lines.append(prefix + merged_item)
            continue

        # 引用ブロック判定
        if trimmed.startswith('>'):
            flush_paragraph()
            quote_text = [trimmed[1:].strip()]
            i += 1
            while i < len(filtered_lines):
                next_line = filtered_lines[i]
                next_trimmed = next_line.strip()
                if not next_trimmed or not next_trimmed.startswith('>'):
                    break
                quote_text.append(next_trimmed[1:].strip())
                i += 1
            merged_quote = ""
            for part in quote_text:
                if not merged_quote:
                    merged_quote = part
                else:
                    last_c = merged_quote[-1]
                    first_c = part[0]
                    if (last_c.isalnum() or last_c in ".,;!?)]}") and (first_c.isalnum() or first_c in "([{$"):
                        merged_quote += " " + part
                    else:
                        merged_quote += part
            out_lines.append("> " + merged_quote)
            continue

        # 通常テキスト行
        cur_paragraph.append(trimmed)
        i += 1

    flush_paragraph()

    # 連続する空行を1行にまとめる
    final_lines = []
    for l in out_lines:
        if l == "":
            if final_lines and final_lines[-1] == "":
                continue
        final_lines.append(l)

    return '\n'.join(final_lines).strip() + '\n'


def validate_markdown(content: str) -> None:
    """整形後の Markdown に禁止された非Markdownゴミデータが残存していないか検証します。"""
    forbidden_patterns = [
        (r'price-id-toolbar', '価格ツールバーの識別子 (price-id-toolbar)'),
        (r'<script\b', '<script> タグ'),
        (r'</script>', '</script> タグ'),
        (r'<div\b', '<div> タグ'),
        (r'<button\b', '<button> タグ'),
        (r'<small\b', '<small> タグ'),
        (r'魅力\s*/\s*売却\s*/\s*観光客', 'ツールバー言及文'),
    ]

    errors = []
    for pattern, name in forbidden_patterns:
        matches = re.findall(pattern, content, flags=re.IGNORECASE)
        if matches:
            errors.append(f"禁止された残骸が検出されました: {name} ({len(matches)}件)")

    if errors:
        for err in errors:
            print(f"Validation Error: {err}", file=sys.stderr)
        raise ValueError(f"Markdown validation failed with {len(errors)} error(s).")


def main():
    parser = argparse.ArgumentParser(description='Update and format companion.jp.md for DartHack')
    parser.add_argument('--source', '-s', type=str, default=None,
                        help='Path to source companion.jp.md from nethack-companion-jp')
    parser.add_argument('--no-ver', action='store_true',
                        help='Do not increment assets/ver')
    parser.add_argument('--no-test', action='store_true',
                        help='Do not run flutter test after update')
    args = parser.parse_args()

    source_path = args.source or find_default_source()
    if not source_path or not os.path.isfile(source_path):
        print(f"Error: Source file not found. Checked: {source_path or DEFAULT_JP_SOURCES}", file=sys.stderr)
        sys.exit(1)

    print(f"Reading source: {source_path}")
    with open(source_path, 'r', encoding='utf-8') as f:
        raw_content = f.read()

    print("Formatting markdown according to AGENTS.md rule 51...")
    formatted = format_markdown(raw_content)

    print("Validating formatted markdown for forbidden HTML/script artifacts...")
    validate_markdown(formatted)

    print(f"Writing books copy: {TARGET_BOOKS}")
    os.makedirs(os.path.dirname(TARGET_BOOKS), exist_ok=True)
    with open(TARGET_BOOKS, 'w', encoding='utf-8', newline='\n') as f:
        f.write(formatted)

    print(f"Writing assets copy: {TARGET_ASSETS}")
    os.makedirs(os.path.dirname(TARGET_ASSETS), exist_ok=True)
    with open(TARGET_ASSETS, 'w', encoding='utf-8', newline='\n') as f:
        f.write(formatted)

    if not args.no_ver:
        if os.path.isfile(VER_FILE):
            with open(VER_FILE, 'r', encoding='utf-8') as f:
                ver_val = int(f.read().strip())
            new_ver = ver_val + 1
            with open(VER_FILE, 'w', encoding='utf-8') as f:
                f.write(f"{new_ver}\n")
            print(f"Incremented {VER_FILE} from {ver_val} to {new_ver}")
        else:
            print(f"Warning: {VER_FILE} not found; skipped version increment")

    print(f"Successfully updated companion.jp.md ({len(formatted.splitlines())} lines).")

    if not args.no_test:
        print("Running Flutter tests...")
        test_path = os.path.join(FLUTTER_ROOT, 'test/widgets/companion_jp_parse_test.dart')
        if os.path.isfile(test_path):
            res = subprocess.run(['flutter', 'test', 'test/widgets/companion_jp_parse_test.dart'],
                                 cwd=FLUTTER_ROOT, shell=True)
            if res.returncode != 0:
                print("Warning: Flutter test failed!", file=sys.stderr)
                sys.exit(res.returncode)
            print("Flutter test passed!")

if __name__ == '__main__':
    main()

