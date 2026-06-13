# unrpyc patches (UnRen-Desktop)

Base: upstream **unrpyc 2.0.4** (see `manifest.json`). Archived reference:
`../../_archive/unren-legacy/unrpyc/unrpyc-2.0.4/`

## Files added or modified vs upstream

| File | Change |
|------|--------|
| `decompiler/renpycompat.py` | `types.GenericAlias` / `types.UnionType` as `FakeIgnore` (Ren'Py 8 type hints in pickles) |
| `decompiler/codegen.py` | Added — legacy Ren'Py 6 `_ast` helpers (`_legacy_ast_type`, `Num`, etc.) for Python 3.12+ |
| `decompiler/screendecompiler.py` | Added — screen decompiler using codegen legacy helpers |
| `decompiler/__init__.py` | Minor diffs vs upstream |
| `unrpyc.py` | Small diffs vs upstream |

## Upgrading from upstream

```bash
# Diff against archive, re-apply patches:
diff -ru _archive/unren-legacy/unrpyc/unrpyc-2.0.4/ tools/unrpyc-py3/
```

Do **not** blind-copy upstream over `tools/unrpyc-py3/` — keep `codegen.py` and `screendecompiler.py`.

Ren'Py &lt; 7 / SL1: UnRen passes `--sl1-as-python` automatically when decompiling py2-era games.
