<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-31. -->
# Modification Notice Template (English)

Use one of the following short notices in each modified file.

## Generic sentence

Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.

## Recommended Automation Policy (Git pre-commit)

- Update modification notices automatically at commit time.
- Update staged files only.
- Exclude paths where appending notices can break file semantics.

### Safe defaults for exclusions

- Exclude files under `dat/` except `dat/**/*.lua`.
- Exclude binary-oriented outputs (for example `binary/`, `vsbinary/`).
- Exclude JSON from auto-append in this repository.

This aligns with NetHack License 2(a) handling in this project: keep upstream raw data intact and use separated localized files such as `*_jp`.

## NetHack License 2(a) Policy Note

If a file format does not support comments (for example, many raw data files under `dat/`), do not modify the original file just to add a notice.
Use a separate localized file (for example, `*_jp`) and keep the original upstream file intact.

## C / C++ / Header

```c
/* Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD. */
```

## Lua

```lua
-- Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.
```

## Markdown

```markdown
<!-- Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD. -->
```

## XML / Visual Studio project files (`.xml`, `.vcxproj`, `.props`, `.targets`)

Use XML comments, and keep the XML declaration as the first line.

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD. -->
```

Do not place plain text (for example, `NOTICE: ...`) before `<?xml ...?>`.

## Resource script (`.rc`)

Use C++-style line comments.

```rc
// Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.
```

Do not use plain text notices like `NOTICE: ...` in `.rc` files.

## YAML / Shell-style config

```yaml
# Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.
```

## NMAKE file (`package\\package.nmake`)

Use a line comment that starts with `#`.

```makefile
# Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.
```

## Plain text

```text
NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.
```

## JSON (object)

Add this top-level property when comments are not allowed:

```json
"modification_notice": "Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD."
```
