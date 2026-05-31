NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-21.
import sys

# マッピング辞書
mapping = {
    "*呪文の書*": "*spellbook*",
    "*蜘蛛*": "*spider*",
    "*杖*": "*wand*",
    "*アスクレピオスの杖*": "*caduceus*",
    "*剣*": "*sword*",
    "*弓懸（ゆがけ）": "*gauntlets*",
    "*ゾンビ*": "*zombie*"
}

file_path = 'dat/data.base'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    stripped = line.strip()
    if stripped in mapping:
        new_lines.append(mapping[stripped] + "\n")
    else:
        new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Replacement complete.")

