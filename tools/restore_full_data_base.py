NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-21.
import sys

# 元ファイルと復元データのパス
file_path = 'dat/data.base'
full_source_path = 'tmp/full_original_data_base.txt' # 全文を含んだファイルを想定

# 1. 復元用データを読み込む
with open(full_source_path, 'r', encoding='utf-8') as f:
    full_original = f.read()

# 2. 現在のファイルを読み込む（キーの英語化は済んでいる前提）
with open(file_path, 'r', encoding='utf-8') as f:
    current_lines = f.readlines()

# 3. 復元用データから grave 以降を抽出する（grave 行を含む）
# grave が見つからない場合はエラー
if 'grave' not in full_original:
    print("Error: grave not found in source.")
    sys.exit(1)

# full_original を grave から末尾まで切り出す
suffix_data = full_original[full_original.find('grave'):]

# 4. 元ファイルも grave から末尾を差し替える
new_lines = []
found = False
for line in current_lines:
    if line.startswith('grave'):
        new_lines.append('grave\n') # grave キーを追加
        found = True
        break
    new_lines.append(line)

if found:
    # grave キーの後の説明文（インデント行）をスキップしてから
    # suffix_data の grave キー以降を連結する
    
    # suffix_data を行分割
    suffix_lines = suffix_data.splitlines(True)
    
    # suffix_lines の最初の行は 'grave' なので、それ以降を連結
    new_lines.extend(suffix_lines[1:])
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Restore complete.")
else:
    print("Error: grave not found in data.base.")

