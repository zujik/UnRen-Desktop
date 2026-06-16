# SDK runtime slices

Trimmed Ren'Py runtimes used when a game folder has no Linux/macOS `lib/` Python.

| Directory | Ren'Py | Era | Linux | macOS (Apple Silicon + Intel) |
|-----------|--------|-----|-------|----------------------------------|
| `py3-8.5.3/` | 8.5.3 | 2024+ (Py3) | `lib/py3-linux-x86_64` | `lib/py3-mac-universal` |
| `py2-7.8.7/` | 7.8.7 | 2019–2024 (Py2) | `lib/py2-linux-x86_64` | `lib/py2-mac-universal` |
| `py2-6.99.14.3/` | 6.99.14 | 2016–2018 (Py2) | `lib/linux-*` | `lib/darwin-x86_64` (Intel/Rosetta) |
| `py2-5.6.7/` | 5.6.7 | 2007–2009 (Py2) | `lib/linux-x86` | — |

UnRen picks the SDK slice from `config.script_version` / bundled `renpy/` metadata, then
falls back to newer slices if the preferred one is missing.

## Local setup

Modern slices (8.5.3 / 7.8.7):

```bash
./scripts/populate-sdk.sh
```

Legacy slices: copy full SDK archives from [renpy.org](https://www.renpy.org/doc/html/changelog.html)
into `sdk/py2-*` (already trimmed layouts are fine).

## Git strategy

SDK binaries under `lib/` and `renpy/` are tracked with **Git LFS** (see `.gitattributes`).

After cloning:

```bash
git lfs install
git lfs pull    # Linux + macOS runtimes (py*-linux-* and py*-mac-universal)
```

If `lib/py3-mac-universal/` or `lib/py2-mac-universal/` is missing after pull, run
`./scripts/populate-sdk.sh` with full SDK trees from renpy.org, or let UnRen fetch
SDK slices from GitHub Releases on first run.

Release tarballs (`scripts/package-sdk-release.sh`) remain an option for forum
users who download a zip without git.
