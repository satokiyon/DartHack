NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-21.
import json

def translate_data_base_with_full_match(input_file, output_file, dictionary_file):
    with open(dictionary_file, 'r', encoding='utf-8') as f:
        dictionary = json.load(f)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in lines:
            stripped = line.strip()
            # 辞書のキーが長文の場合は、その行の内容と一致するかを判断
            # ここでは辞書のキーをその行の文字列そのものとして処理
            if stripped in dictionary:
                f.write("\t" + dictionary[stripped] + '\n')
            else:
                f.write(line)

if __name__ == "__main__":
    translate_data_base_with_full_match('dat/data.base', 'dat/data.base.new', 'dat/fungi_translation_dict.json')

