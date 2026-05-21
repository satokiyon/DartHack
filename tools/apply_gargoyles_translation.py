import json

def translate_data_base_with_full_match(input_file, output_file, dictionary_file):
    with open(dictionary_file, 'r', encoding='utf-8') as f:
        dictionary = json.load(f)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in lines:
            stripped = line.strip()
            # 辞書のキーと行の文字列が一致する場合のみ翻訳を適用
            if stripped in dictionary:
                f.write("\t" + dictionary[stripped] + '\n')
            else:
                f.write(line)

if __name__ == "__main__":
    translate_data_base_with_full_match('dat/data.base', 'dat/data.base.new', 'dat/gargoyles_translation_dict.json')
