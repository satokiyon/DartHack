## Summary

- What changed?
- Why is this needed?

## Scope

- [ ] Source code (`src/`, `include/`, `sys/`)
- [ ] Translation/text (`dat/`, `docs/`, README)
- [ ] Build/config only

## Validation

- [ ] Build succeeds locally
- [ ] Relevant runtime behavior checked
- [ ] No unintended file changes included

Commands run (if any):

```
# example
# msbuild sys\\windows\\vs\\NetHack.sln '/t:NetHack;NetHackW' /p:Configuration=Debug /p:Platform=x64
```

## Checklist

- [ ] Security-sensitive changes reviewed
- [ ] License/notice impact checked
- [ ] Related issue linked
