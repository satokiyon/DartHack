import sys

file_path = 'dat/data.base'
full_source_path = 'tmp/full_original_data_base.txt'

# 原文を読み込む
with open(full_source_path, 'r', encoding='utf-8') as f:
    full_original = f.read()

# 現在のファイルを読み込む
with open(file_path, 'r', encoding='utf-8') as f:
    current_lines = f.readlines()

# 復旧地点: 'grave'
# graveが見つからない場合は終了
if 'grave' not in full_original:
    print("Error: grave not found in source.")
    sys.exit(1)

# 新しいファイルの構築
# grave 以降の原文を取得
suffix_data = full_original[full_original.find('grave'):]

new_lines = []
found = False
for line in current_lines:
    if line.startswith('grave'):
        new_lines.append(line) # 現在のファイルの grave キー
        found = True
        break
    new_lines.append(line)

if found:
    # grave 以降を原文の内容（grave キー行以外）で置き換える
    suffix_lines = suffix_data.splitlines(True)
    new_lines.extend(suffix_lines[1:]) # suffix_lines[0] は 'grave' なのでスキップ
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Restore complete.")
else:
    print("Error: grave not found in data.base.")
