NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-21.
import sys

# パス設定
file_path = 'dat/data.base'
original_data_path = 'tmp/full_original_data_base.txt'

# 原文データの読み込み（UTF-8で読み込めない場合を考慮）
try:
    with open(original_data_path, 'r', encoding='utf-8') as f:
        full_original = f.read()
except UnicodeDecodeError:
    # 失敗した場合は cp932 (Windowsのデフォルト) などで再試行
    with open(original_data_path, 'r', encoding='cp932') as f:
        full_original = f.read()

# 現在のファイルを読み込む
with open(file_path, 'r', encoding='utf-8') as f:
    current_lines = f.readlines()

# 復旧地点: '*golem'
# この行より前の内容は維持し、それ以降を全文復元する
target_key = '*golem'

new_lines = []
found = False
for line in current_lines:
    new_lines.append(line)
    if line.strip() == target_key:
        found = True
        break

if found:
    # full_original から *golem を探す
    if target_key in full_original:
        # *golem 以降の原文を取得
        start_idx = full_original.find(target_key)
        
        # original の続きを連結する
        # full_original の該当位置から末尾までを文字列として取得
        suffix_data = full_original[start_idx:]
        
        # 行分割して結合
        suffix_lines = suffix_data.splitlines(True)
        # 最初の行は '*golem' なのでスキップ
        new_lines.extend(suffix_lines[1:])
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print("Full restore complete.")
    else:
        print("Error: *golem not found in original source.")
else:
    print("Error: *golem not found in current file.")

