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

SDK binaries under `lib/` and `renpy/` are tracked with **Git LFS** (see `.gitattributes`).

After cloning:

```bash
git lfs pull          # fetch LFS objects (if you use LFS for sdk/)
./scripts/populate-sdk.sh   # or rebuild locally from full Ren'Py SDKs
```

Small files (`renpy.sh`, `renpy.py`, `LICENSE.txt`) stay in normal git.

Release tarballs (`scripts/package-sdk-release.sh`) remain an option for forum
users who download a zip without git.
