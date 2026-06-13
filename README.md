# UnRen-Desktop

Ren'Py unpack, decompile, and patch tool for **Linux and macOS** — a desktop port of [UnRen.bat](https://f95zone.to/threads/3083/) by [Sam](https://github.com/F95Sam), with features from [UnRen-Ultrahack](https://f95zone.to/threads/92717/) by [VepsrP](https://f95zone.to/members/vepsrp.329951/).

Formerly known as **UnRen-Linux.sh**; renamed to reflect cross-platform support.

## Quick start

UnRen is a **folder tool**, not a single script. You need `UnRen.sh` plus `unren/`, `tools/`, `patches/`, and `sdk/`.

**Important:** Ren'Py games already have a `lib/` folder (Python runtime). UnRen bash modules live in **`unren/`**, not `lib/`. Copying everything into a game root is fine — but do not expect UnRen modules to appear under the game's `lib/`.

### Option A — Run from the repo (no copy into game)

```bash
git clone https://github.com/zujik/UnRen-Desktop.git
cd UnRen-Desktop
git lfs pull
./UnRen.sh /path/to/GameFolder
```

### Option B — Copy into the game (classic UnRen style)

Copy **all** UnRen-Desktop files and folders into the game. Two layouts work:

**B1 — Flat into game root** (same layout as original UnRen.bat):

```
GameFolder/
├── game/
├── renpy/
├── lib/                ← game's Python (unchanged)
├── UnRen.sh
├── unren/              ← UnRen bash modules (not lib/)
├── tools/
├── patches/
└── sdk/
```

```bash
cd /path/to/GameFolder
./UnRen.sh
```

**B2 — Subfolder** (keeps game root cleaner):

```
GameFolder/
├── game/
├── renpy/
└── UnRen/              ← full UnRen-Desktop contents here
    ├── UnRen.sh
    ├── unren/
    ├── tools/
    ├── patches/
    └── sdk/
```

```bash
cd /path/to/GameFolder/UnRen
./UnRen.sh
```

The script auto-detects the game when `game/` and `renpy/` are in the current folder, or in the parent folder (B2).

**Do not** copy only `UnRen.sh` — that will fail with missing `unren/` errors.

### macOS

Double-click `UnRen.command`, or use Option A/B above.

## What it does

| Option | Action |
|--------|--------|
| 1 | Extract RPA archives (renames `.rpa` → `.rpa.bak` after extraction) |
| 2 | Decompile `.rpyc` → `.rpy` |
| 3–6 | Console, quick save/load, skip, rollback patches |
| 7 | Options 3–6 (patches only) |
| 8 | Options 1–6 + install `GameName.sh` launcher |
| 9 | Options 1–6 + deobfuscate + install launcher |
| 0 | Decompile and overwrite existing `.rpy` files |
| g | Install / launch game (`GameName.sh` from `unren/templates/renpy-desktop.sh`, `lib/` then `sdk/`) |

## Launching games (Linux display)

UnRen installs **`GameName.sh`** and **`GameName.py`** from the templates in `unren/templates/`:

- `renpy-desktop.sh` → renamed to match the game (from `.exe`, existing `.sh`, or `build.name`)
- `renpy-desktop.py` → header comments + SDK `renpy.py` body for `GameName.py`

**Always launch via `GameName.sh`**, not by running the `.py` directly.

### Wayland desktops and legacy games

Ren'Py **py2** builds (including SDK fallback for Windows-only games) ship an old `pygame_sdl2` without native Wayland. On a Wayland session (`XDG_SESSION_TYPE=wayland`), SDL may try Wayland first and crash with `wayland not available`.

For those **py2** runtimes, `GameName.sh` automatically sets `SDL_VIDEODRIVER=x11` so the game runs through **XWayland**.

**py3** games (native Linux `lib/` or `sdk/py3-*`) do not get this override. Modern SDL2 already matches the session (Wayland on Wayland, X11 on X11) and falls back if native Wayland is unavailable — no shell-side driver switching needed.

### Regenerate or override

| Goal | What to do |
|------|------------|
| Pick up UnRen launcher updates | Re-run option **g**, **8**, or **9** (rewrites `GameName.sh`) |
| Force native Wayland (modern games) | `SDL_VIDEODRIVER=wayland ./GameName.sh` |
| Force X11 / XWayland | `SDL_VIDEODRIVER=x11 ./GameName.sh` |
| UnRen override without clobbering your shell | `UNREN_SDL_VIDEODRIVER=x11 ./GameName.sh` |
| Skip first-run GL performance test | `RENPY_PERFORMANCE_TEST=0 ./GameName.sh` |

## Python runtime strategy

1. **Game-bundled Python** (preferred) — uses the game's own `lib/…/python` when present.
2. **Bundled SDK** — version picked from `script_version` (see `sdk/README.md`):
   - `py3-8.5.3` (Ren'Py 8+)
   - `py2-7.8.7` (Ren'Py 7)
   - `py2-6.99.14.3` (Ren'Py 6)
   - `py2-5.6.7` (Ren'Py 5, 32-bit Linux)
3. **Download fallback** — `scripts/populate-sdk.sh` can fetch modern slices from renpy.org if missing.

Legacy slices are copied manually from [renpy.org](https://www.renpy.org/) archives.

## Project layout

```
UnRen-Desktop/
├── UnRen.sh              # main entry (Linux + macOS terminal)
├── UnRen.command         # macOS Finder double-click wrapper
├── unren/                # bash modules (not lib/ — games use lib/ for Python)
│   └── templates/        # renpy-desktop.sh / renpy-desktop.py launcher templates
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
