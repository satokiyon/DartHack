# Modification Notice Template (English)

Use one of the following short notices in each modified file.

## Generic sentence

Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.

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

## Plain text

```text
NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD.
```

## JSON (object)

Add this top-level property when comments are not allowed:

```json
"modification_notice": "Modified by NetHackJP contributor @satokiyon; latest change date: YYYY-MM-DD."
```
