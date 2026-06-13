# UnRen-Desktop

Ren'Py unpack, decompile, and patch tool for **Linux and macOS** — a desktop port of [UnRen.bat](https://f95zone.to/threads/3083/) by [Sam](https://github.com/F95Sam), with features from [UnRen-Ultrahack](https://f95zone.to/threads/92717/) by [VepsrP](https://f95zone.to/members/vepsrp.329951/).

Formerly known as **UnRen-Linux.sh**; renamed to reflect cross-platform support.

## Quick start

1. Clone or download this repository.
2. Run `scripts/populate-sdk.sh` once (copies trimmed Ren'Py runtimes from local SDK archives — see below).
3. Place `UnRen.sh` (or `UnRen.command` on Mac) inside the game folder, or pass the game path as an argument.
4. Run `./UnRen.sh` or double-click `UnRen.command`.

```bash
./UnRen.sh /path/to/GameFolder
# or for macOS .app bundles:
./UnRen.sh "/path/to/Game.app"
```

## What it does

| Option | Action |
|--------|--------|
| 1 | Extract RPA archives |
| 2 | Decompile `.rpyc` → `.rpy` |
| 3–6 | Console, quick save/load, skip, rollback patches |
| 7–9 | Combinations of the above |
| 0 | Decompile and overwrite existing `.rpy` files |

## Python runtime strategy

1. **Game-bundled Python** (preferred) — uses the game's own `lib/…/python` when present.
2. **Bundled SDK** (`sdk/py3-8.5.3`, `sdk/py2-7.8.7`) — trimmed Ren'Py runtimes for Windows-only game folders.
3. **Download fallback** — `scripts/populate-sdk.sh` can fetch from renpy.org if local SDK folders are missing.

Pinned SDK versions: **Ren'Py 8.5.3** (Python 3) and **7.8.7** (Python 2).

## Project layout

```
UnRen-Desktop/
├── UnRen.sh              # main entry (Linux + macOS terminal)
├── UnRen.command         # macOS Finder double-click wrapper
├── lib/                  # bash modules
├── tools/                # rpatool + unrpyc (plain Python, not base64)
├── patches/              # .rpy patch templates
├── sdk/                  # trimmed Ren'Py runtime slices
├── scripts/              # populate-sdk.sh, build-release.sh
└── manifest.json         # pinned versions and download URLs
```

## SDK setup

SDK runtime binaries (`sdk/*/lib/`, `sdk/*/renpy/`) are stored with **Git LFS**.
Plain git objects stay small; clones need `git lfs` installed (you have 3.7.1).

| Approach | When to use |
|----------|-------------|
| **`git lfs pull` (default for clones)** | After clone — fetches pinned runtimes from the repo |
| **`populate-sdk.sh`** | Rebuild from local full SDK trees, or if LFS fetch fails |
| **GitHub Release tarballs** | Forum zip downloads without git — `scripts/package-sdk-release.sh` |

**Clone workflow:**

```bash
git clone https://github.com/zujik/UnRen-Desktop.git
cd UnRen-Desktop
git lfs pull
```

**Local rebuild** (if you have full SDKs next to the repo):

```bash
./scripts/populate-sdk.sh
```

Or custom paths:

```bash
RENPY_PY3_SRC=/path/to/renpy-8.5.3-sdk \
RENPY_PY2_SRC=/path/to/renpy-7.8.7-sdk \
./scripts/populate-sdk.sh
```

**Release tarballs** (optional, for non-git users):

```bash
./scripts/package-sdk-release.sh
```

## Lineage

- [UnRen.bat](https://github.com/F95Sam/UnRen) — Sam
- [UnRen-Ultrahack](https://f95zone.to/threads/92717/) — VepsrP
- [UnRen-Linux.sh](https://github.com/zujik/UnRen-Linux.sh) — Troy Dallas
- [UnRen for Mac 0.9.0](https://f95zone.to/threads/16887/) — huchukato (Python 3 / unrpyc v2)
- [dikau-UnRen-sh](https://github.com/dikau/UnRen-sh) — cleaner bash structure

## Third-party tools

- [unrpyc](https://github.com/CensoredUsername/unrpyc) — MIT
- [rpatool](https://codeberg.org/shiz/rpatool) — WTFPL
- Ren'Py SDK components — MIT / LGPL (see `THIRD_PARTY_LICENSES.md`)

## License

MIT — see `LICENSE`.
