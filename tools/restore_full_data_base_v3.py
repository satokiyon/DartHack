import sys

# パス設定
file_path = 'dat/data.base'
# ユーザーから提供された最新の正しい英語ソースを tmp/full_original_data_base.txt に保存済みとする
full_source_path = 'tmp/full_original_data_base.txt'

# 1. 復旧用データの読み込み
with open(full_source_path, 'r', encoding='utf-8') as f:
    full_original = f.read()

# 2. 現在のファイルを読み込む
with open(file_path, 'r', encoding='utf-8') as f:
    current_lines = f.readlines()

# 3. 復旧地点: '*golem'
# この行までを維持し、それ以降を全文復元する
target_key = '*golem'

# 現在のファイルがどこまであるかを確認し、*golem の行まで取得
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
        # full_original の該当位置以降を全て抽出
        # 1. *golem というキーを持つエントリーを特定するために改行を含めて検索
        # 2. その位置以降をすべて full_original からコピー
        
        # 文字列として特定位置から末尾まで切り出す
        start_idx = full_original.find(target_key)
        
        # 復元データ（*golem を含む）
        suffix_data = full_original[start_idx:]
        
        # 行分割して結合（new_linesには既に '*golem\n' が入っている）
        suffix_lines = suffix_data.splitlines(True)
        # 最初の行('*golem')は重複するのでスキップして追加
        new_lines.extend(suffix_lines[1:])
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print("Full restore complete.")
    else:
        print("Error: *golem not found in source.")
else:
    print("Error: *golem not found in current file.")
