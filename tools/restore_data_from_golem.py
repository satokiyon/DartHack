NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-21.
import sys

file_path = 'dat/data.base'
full_source_path = 'tmp/full_original_data_base.txt'

# 1. 元の英語版データ全体を読み込む
with open(full_source_path, 'r', encoding='utf-8') as f:
    full_original = f.read()

# 2. 現在のファイルを読み込む
with open(file_path, 'r', encoding='utf-8') as f:
    current_lines = f.readlines()

# 3. 復旧地点: '*golem' の直後からファイル末尾までを原文から取得
# これにより、*golemより後のデータ全てを英語版に復旧する
target_key = '*golem'

# target_key を含む行を探す
golem_index = -1
for i, line in enumerate(current_lines):
    if line.strip() == target_key:
        golem_index = i
        break

if golem_index != -1:
    # 1. *golem 行までの内容は現在のものを維持（キーの英語化済み）
    new_lines = current_lines[:golem_index + 1]
    
    # 2. full_original から '*golem' 行以降の全内容を取得
    if target_key in full_original:
        # full_original 内の '*golem' の位置を探す
        start_idx = full_original.find(target_key)
        # その後の全データ（行分割）
        suffix_lines = full_original[start_idx:].splitlines(True)
        
        # 最初の行('*golem')は重複するのでスキップして追加
        new_lines.extend(suffix_lines[1:])
        
        # 保存
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print("Full restore from *golem successful.")
    else:
        print("Error: *golem not found in source.")
else:
    print("Error: *golem not found in current file.")

