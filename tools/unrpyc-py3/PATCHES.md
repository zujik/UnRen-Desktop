# unrpyc patches (UnRen-Desktop)

Base: upstream **unrpyc 2.0.4** (see `manifest.json`).

## Files added or modified vs upstream

| File | Change |
|------|--------|
| `decompiler/renpycompat.py` | `types.GenericAlias` / `types.UnionType` as `FakeIgnore` (Ren'Py 8 type hints in pickles) |
| `decompiler/codegen.py` | Added — legacy Ren'Py 6 `_ast` helpers (`_legacy_ast_type`, `Num`, etc.) for Python 3.12+ |
| `decompiler/screendecompiler.py` | Added — screen decompiler using codegen legacy helpers |
| `decompiler/__init__.py` | Minor diffs vs upstream |
| `unrpyc.py` | Small diffs vs upstream |

## Upgrading from upstream

Clone upstream v2.0.4 beside this tree, then diff:

```bash
git clone --depth 1 --branch v2.0.4 https://github.com/CensoredUsername/unrpyc.git /tmp/unrpyc-2.0.4
diff -ru /tmp/unrpyc-2.0.4/ tools/unrpyc-py3/
```

Do **not** blind-copy upstream over `tools/unrpyc-py3/` — keep `codegen.py` and `screendecompiler.py`.

Ren'Py &lt; 7 / SL1: UnRen passes `--sl1-as-python` automatically when decompiling py2-era games.
