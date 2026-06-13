# SDK runtime slices

Trimmed Ren'Py runtimes used when a game folder has no Linux/macOS `lib/` Python.

| Directory | Ren'Py | Era | Linux launch |
|-----------|--------|-----|--------------|
| `py3-8.5.3/` | 8.5.3 | 2024+ (Py3) | yes |
| `py2-7.8.7/` | 7.8.7 | 2019–2024 (Py2) | yes |
| `py2-6.99.14.3/` | 6.99.14 | 2016–2018 (Py2) | yes (`lib/linux-*`) |
| `py2-5.6.7/` | 5.6.7 | 2007–2009 (Py2) | yes (`lib/linux-x86`, 32-bit) |
| `py2-4.8.10/` | 4.8.10 | 2005–2006 | Windows SDK only (no Linux `lib/`) |

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
git lfs pull
./scripts/populate-sdk.sh   # for py3/py2 modern slices if needed
```

Release tarballs (`scripts/package-sdk-release.sh`) remain an option for forum
users who download a zip without git.
