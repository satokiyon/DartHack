# 重複・不整合が発生した末尾部分を正しい原文に復元するスクリプト

file_path = 'dat/data.base'
suffix_path = 'tmp/restored_data_base_suffix.txt'

# 復元データの読み込み
with open(suffix_path, 'r', encoding='utf-8') as f:
    suffix_data = f.read()

# 元ファイルの読み込み
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# *gem の位置を探す
new_lines = []
found = False
for line in lines:
    if line.startswith('*gem'):
        new_lines.append(line)
        found = True
        break
    new_lines.append(line)

if found:
    # *gem 以降を原文に置き換える
    # suffix_data の最初の行は NetHack 5.0 data.base なので
    # *gem を含んでいる箇所を探す
    
    # 実際には suffix_data 全体を書き出すのではなく
    # *gem 行の次から suffix_data の該当箇所を連結する
    
    # 簡単のため、suffix_data から *gem 以降を取り出して連結する
    # suffix_data を行ごとに分割
    suffix_lines = suffix_data.splitlines(True)
    
    start_copy = False
    for sline in suffix_lines:
        if sline.startswith('*gem'):
            start_copy = True
            continue # *gem 行は既に new_lines にある
        if start_copy:
            new_lines.append(sline)
    
    # 保存
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Restore complete.")
else:
    print("Error: *gem not found.")
