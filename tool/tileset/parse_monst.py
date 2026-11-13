# -*- coding: utf-8 -*-
import re
import json

with open("c_core/nethack_en/include/monsters.h", "r", encoding="latin1") as f:
    content = f.read()

# MON(NAM("name") または MON(NAMS(...) , S_CLASS, ...)
pattern = r'MON\s*\(\s*(?:NAM\s*\(\s*"([^"]+)"\s*\)|NAMS\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\))\s*,\s*([A-Za-z0-9_]+)'
matches = re.findall(pattern, content)
print(f"Total MON entries in monsters.h: {len(matches)}")

classes = {}
mons_list = []
for m in matches:
    if m[0]:
        name = m[0]
        m_name = f_name = n_name = name
    else:
        m_name = m[1]
        f_name = m[2]
        n_name = m[3] if m[3] else m_name
        name = m_name
    s_cls = m[4]
    mons_list.append({"name": name, "m": m_name, "f": f_name, "n": n_name, "s_class": s_cls})
    classes.setdefault(s_cls, []).append(name)

for s_cls, mons in classes.items():
    print(f"{s_cls:15s}: {len(mons):2d} mons -> {', '.join(mons[:4])} ...")

with open("tool/tileset/monst_classes.json", "w", encoding="utf-8") as f:
    json.dump(classes, f, ensure_ascii=False, indent=2)

with open("tool/tileset/mons_list.json", "w", encoding="utf-8") as f:
    json.dump(mons_list, f, ensure_ascii=False, indent=2)
