# SDK runtime slices

Trimmed Ren'Py runtimes used when a game folder has no Linux/macOS `lib/` Python.

| Directory | Ren'Py | Python |
|-----------|--------|--------|
| `py3-8.5.3/` | 8.5.3 | 3 |
| `py2-7.8.7/` | 7.8.7 | 2 |

## Local setup

From the repo root:

```bash
./scripts/populate-sdk.sh
```

Uses `../renpy-8.5.3-sdk` and `../renpy-7.8.7-sdk` by default, or set `RENPY_PY3_SRC` / `RENPY_PY2_SRC`.

## Git strategy

Large binaries under `lib/` and `renpy/` are **not committed** on the development branch.
Small launcher files (`renpy.sh`, `renpy.py`, `LICENSE.txt`) may be committed.

For releases, prefer **GitHub Release tarballs** (`scripts/package-sdk-release.sh`).
Git LFS is an alternative if you want binaries versioned inside git — see root `README.md`.
