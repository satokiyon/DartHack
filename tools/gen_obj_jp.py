#!/usr/bin/env python3
"""
gen_obj_jp.py - Generate src/obj_jp.c from current (JP) objects.h
Extracts JP names and descrs, paired with upstream EN enum constants.
Usage: python tools/gen_obj_jp.py
"""
import re
import subprocess
import sys
import os

REPO = r"C:\Users\satok\NetHackJP"
JP_OBJECTS_H  = os.path.join(REPO, "include", "objects.h")
OUTPUT_C      = os.path.join(REPO, "src", "obj_jp.c")

# ---- helpers ---------------------------------------------------------------

def read_file(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def read_git(refspec, path):
    """Read a file from a git ref."""
    result = subprocess.run(
        ["git", "show", f"{refspec}:{path}"],
        capture_output=True, text=True, cwd=REPO, encoding="utf-8"
    )
    if result.returncode != 0:
        raise RuntimeError(f"git show failed: {result.stderr}")
    return result.stdout

def strip_c_line_comments(text):
    """Remove // style comments from text."""
    return re.sub(r'//[^\n]*', '', text)

def parse_objects(text):
    """
    Parse objects.h content and return a list of dicts:
      { 'enum': 'DAGGER', 'name': '短剣'|'dagger', 'descr': None|'str' }
    in definition order (matches objects[] array order).

    All item-defining macros have the form:
      MACRONAME(name, desc_or_second_arg, ..., ENUM_CONST)
    where name is always a quoted string (first arg) and ENUM_CONST
    is the last argument.  OBJECT( wraps OBJ(name,desc) as first arg.
    """
    # Remove block comments to simplify parsing
    text = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group().count('\n'),
                  text, flags=re.DOTALL)
    text = strip_c_line_comments(text)

    n = len(text)

    def skip_string(pos):
        """pos points at opening '"'; return position after closing '"'."""
        pos += 1
        while pos < n:
            c = text[pos]
            if c == '\\':
                pos += 2
                continue
            if c == '"':
                return pos + 1
            pos += 1
        return pos

    def collect_balanced(pos):
        """
        pos points at '('; collect until matching ')'.
        Returns (inner_text, end_pos).
        """
        assert text[pos] == '('
        depth = 0
        start = pos + 1
        pos += 1
        while pos < n:
            c = text[pos]
            if c == '"':
                pos = skip_string(pos)
                continue
            if c == '(':
                depth += 1
            elif c == ')':
                if depth == 0:
                    return text[start:pos], pos + 1
                depth -= 1
            pos += 1
        return text[start:], n

    def split_top_args(s):
        """
        Split comma-separated top-level args in s (not inside parens/quotes).
        Returns list of arg strings (stripped).
        """
        args = []
        depth = 0
        cur = []
        i = 0
        m = len(s)
        while i < m:
            c = s[i]
            if c == '"':
                end = skip_string(i)
                cur.append(s[i:end])
                i = end
                continue
            if c == '(':
                depth += 1
                cur.append(c)
            elif c == ')':
                depth -= 1
                cur.append(c)
            elif c == ',' and depth == 0:
                args.append(''.join(cur).strip())
                cur = []
                i += 1
                continue
            else:
                cur.append(c)
            i += 1
        if cur:
            args.append(''.join(cur).strip())
        return args

    def extract_quoted(s):
        """Extract the first quoted string value from s, or None."""
        m = re.search(r'"((?:[^"\\]|\\.)*)"', s)
        return m.group(1) if m else None

    # Macros whose first arg is name and second is desc (or stone/text/typ...)
    # OBJECT() is special: first arg is OBJ(name, desc)
    ITEM_MACROS = re.compile(
        r'(?<![a-zA-Z_])(?:'
        r'WEAPON|BOW|ARMOR|GLOVES|RING|AMULET_WITH_BONUS|AMULET|'
        r'TOOL|FOOD|POTION|SCROLL|SPBOOK|WAND|GEM|OBJECT'
        r')\s*\(',
        re.MULTILINE
    )
    # Macros that don't define game objects (only emit display/generic items)
    SKIP_MACRO = re.compile(r'#define\s+')

    results = []

    for m in ITEM_MACROS.finditer(text):
        # Skip if this match is inside a #define line
        line_start = text.rfind('\n', 0, m.start()) + 1
        line_prefix = text[line_start:m.start()].strip()
        if line_prefix.startswith('#'):
            continue

        macro_name = m.group().rstrip('(').strip()
        paren_start = m.end() - 1

        inner, _end = collect_balanced(paren_start)
        args = split_top_args(inner)

        if len(args) < 2:
            continue

        if macro_name == 'OBJECT':
            # First arg is OBJ(name, desc) — parse it directly
            obj_arg = args[0].strip()
            # obj_arg looks like: OBJ("name", "desc") or OBJ("name", NoDes)
            obj_inner_m = re.match(r'\s*OBJ\s*\((.*)\)\s*$', obj_arg, re.DOTALL)
            if not obj_inner_m:
                continue
            obj_args = split_top_args(obj_inner_m.group(1))
            if len(obj_args) < 1:
                continue
            name_arg = obj_args[0]
            desc_arg = obj_args[1] if len(obj_args) > 1 else ''
            last_arg_list = args[1:]  # remaining after OBJ(...)
        else:
            name_arg = args[0]
            desc_arg = args[1]
            last_arg_list = args[2:]

        # Extract name string
        jp_name = extract_quoted(name_arg)
        if jp_name is None:
            continue  # e.g. "generic " concatenation - skip

        # Extract desc string (may be NoDes = None)
        jp_descr = extract_quoted(desc_arg)

        # Extract enum constant: last arg, should be an identifier
        if not last_arg_list:
            continue
        enum_const = last_arg_list[-1].strip()
        if not re.fullmatch(r'[A-Z][A-Z0-9_]+', enum_const):
            continue  # Not an expected enum constant

        results.append({
            'enum': enum_const,
            'name': jp_name,
            'descr': jp_descr,
        })

    return results

def c_escape(s):
    """Escape a Python string for use in a C string literal."""
    return s.replace('\\', '\\\\').replace('"', '\\"')

def generate_obj_jp_c(jp_entries, en_entries):
    """
    jp_entries: list of dicts from JP objects.h
    en_entries: list of dicts from EN objects.h
    Returns the text of src/obj_jp.c
    """
    # Build map: enum_const -> entry for each set
    # We rely on ordering being identical; also build by enum key
    jp_by_enum = {e['enum']: e for e in jp_entries}
    en_by_enum = {e['enum']: e for e in en_entries}

    # Collect all enum consts in order (use EN order as authoritative)
    all_enums = [e['enum'] for e in en_entries]

    # ---- names section ----
    names_lines = []
    descrs_lines = []
    skipped_names = []
    skipped_descrs = []

    for enum in all_enums:
        en = en_by_enum.get(enum)
        jp = jp_by_enum.get(enum)
        if not jp:
            skipped_names.append(f"    /* {enum}: no JP entry */")
            continue

        jp_name = jp['name']
        en_name = en['name'] if en else '?'

        # Only add to names if JP name differs from EN name
        if jp_name != en_name:
            names_lines.append(
                f"    [{enum}] = \"{c_escape(jp_name)}\","
            )

        # descr
        jp_descr = jp.get('descr')
        en_descr = en.get('descr') if en else None
        if jp_descr and jp_descr != en_descr:
            descrs_lines.append(
                f"    [{enum}] = \"{c_escape(jp_descr)}\","
            )

    header = """\
/* obj_jp.c - Japanese display names for NetHack objects.
 * Auto-generated by tools/gen_obj_jp.py
 * Internal keys (OBJ_NAME) remain English for Lua/wish/upstream compat.
 * Display functions use jp_item_name() / jp_item_descr() instead.
 */
#include "hack.h"

/* Japanese display names indexed by otyp.
 * NULL entries fall back to English OBJ_NAME(objects[otyp]).
 * oc_name_idx == otyp always (never shuffled), so otyp index is correct.
 */
const char *const obj_jp_names[NUM_OBJECTS + 1] = {
"""
    names_body = "\n".join(names_lines)
    mid = """
    [NUM_OBJECTS] = NULL /* sentinel */
};

/* Japanese unidentified appearance names, indexed by otyp (initial value).
 * jp_item_descr() uses objects[otyp].oc_descr_idx to follow shuffle,
 * matching OBJ_DESCR's reference chain.
 */
const char *const obj_jp_descrs[NUM_OBJECTS + 1] = {
"""
    descrs_body = "\n".join(descrs_lines)
    footer = """
    [NUM_OBJECTS] = NULL /* sentinel */
};

const char *
jp_item_name(int otyp)
{
    if (otyp >= 0 && otyp < NUM_OBJECTS && obj_jp_names[otyp])
        return obj_jp_names[otyp];
    return OBJ_NAME(objects[otyp]);
}

const char *
jp_item_descr(int otyp)
{
    /* Follow oc_descr_idx shuffle chain, same as OBJ_DESCR() */
    int idx = objects[otyp].oc_descr_idx;

    if (idx >= 0 && idx < NUM_OBJECTS && obj_jp_descrs[idx])
        return obj_jp_descrs[idx];
    return OBJ_DESCR(objects[otyp]);
}
"""
    return header + names_body + mid + descrs_body + footer

# ---- main ------------------------------------------------------------------

def main():
    print("Reading current (JP) objects.h ...")
    jp_text = read_file(JP_OBJECTS_H)
    jp_entries = parse_objects(jp_text)
    print(f"  Parsed {len(jp_entries)} JP entries")

    print("Reading upstream (EN) objects.h from git ...")
    en_text = read_git("upstream-base", "include/objects.h")
    en_entries = parse_objects(en_text)
    print(f"  Parsed {len(en_entries)} EN entries")

    # Diagnostics: check counts match
    if len(jp_entries) != len(en_entries):
        print(f"WARNING: count mismatch (JP={len(jp_entries)}, EN={len(en_entries)})")
        jp_enums = {e['enum'] for e in jp_entries}
        en_enums = {e['enum'] for e in en_entries}
        only_jp = jp_enums - en_enums
        only_en = en_enums - jp_enums
        if only_jp:
            print(f"  Only in JP: {sorted(only_jp)}")
        if only_en:
            print(f"  Only in EN: {sorted(only_en)}")

    print(f"Generating {OUTPUT_C} ...")
    code = generate_obj_jp_c(jp_entries, en_entries)
    with open(OUTPUT_C, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"Done. Written to {OUTPUT_C}")

    # Summary stats
    names_count = code.count("    [") - code.count("[NUM_OBJECTS]")
    print(f"  Approx entries: {names_count} total name+descr entries")

if __name__ == "__main__":
    main()
