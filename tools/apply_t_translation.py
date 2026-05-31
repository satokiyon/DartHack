NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-21.
import json

def translate_data_base(input_file, output_file, dictionary_file):
    with open(dictionary_file, 'r', encoding='utf-8') as f:
        dictionary = json.load(f)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in lines:
            stripped = line.strip()
            if stripped in dictionary:
                f.write(dictionary[stripped] + '\n')
            else:
                f.write(line)

if __name__ == "__main__":
    translate_data_base('dat/data.base', 'dat/data.base.new', 'dat/t_translation_dict.json')

