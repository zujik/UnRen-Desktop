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
| 1 | Extract RPA/JAS/RPC (rpatool + altrpatool fallback; renames to `.bak`) |
| 2 | Decompile `.rpyc` → `.rpy` |
| 3–6 | Console, quick save/load, skip, rollback patches |
| 7 | Options 3–6 (patches only) |
| 8 | Options 1–6 + install `GameName.sh` launcher |
| 9 | Options 1–6 + rpycCorrector + deobfuscate + install launcher |
| 0 | Decompile and overwrite stub/missing `.rpy` only |
| c | rpycCorrector only (mangled RPYC signatures) |
| n | Disable Ren'Py cloud sync (`unren-nsync.rpy`) |
| r | Restore `.org` backups (`.rpa.org`, `.rpy.org`, …) |
| m | macOS only: remove Gatekeeper quarantine (opt-in) |
| g | Install / launch game (`GameName.sh` from `unren/templates/renpy-desktop.sh`, `lib/` then `sdk/`) |

## Launching games (Linux display)

UnRen installs **`GameName.sh`** and **`GameName.py`** from the templates in `unren/templates/`:

- `renpy-desktop.sh` → renamed to match the game (from `.exe`, existing `.sh`, or `build.name`)
- `renpy-desktop.py` → header comments + SDK `renpy.py` body for `GameName.py`

**Always launch via `GameName.sh`**, not by running the `.py` directly.

### Wayland desktops and legacy games

Ren'Py **py2** builds (including SDK fallback for Windows-only games) ship an old `pygame_sdl2` without native Wayland. On a Wayland session (`XDG_SESSION_TYPE=wayland`), SDL may try Wayland first and crash with `wayland not available`.

For **py2** runtimes, `GameName.sh` sets `SDL_VIDEODRIVER=x11` on Linux. This covers Wayland desktops **and** environments where KDE (or similar) already exports `SDL_VIDEODRIVER=wayland` — old `pygame_sdl2` cannot use native Wayland and crashes with `wayland not available`.

**py3** games (native Linux `lib/` or `sdk/py3-*`) do not get this override. Modern SDL2 already matches the session and falls back if native Wayland is unavailable.

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
├── licenses/             # per-component license texts (runtime audit)
├── sdk/                  # trimmed Ren'Py runtime slices
├── docs/
│   └── SOURCE_INVENTORY.md  # provenance audit trail
├── scripts/              # populate-sdk.sh, build-release.sh, verify_compliance.py
└── manifest.json         # pinned versions, compliance_block, mirror URLs
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

**Rebuild SDK slices** (when `git lfs pull` is insufficient):

```bash
# Download full SDKs from renpy.org, then point populate-sdk.sh at them:
RENPY_SDK_SOURCES=/path/to/sdk-sources \
RENPY_PY3_SRC=/path/to/renpy-8.5.3-sdk \
RENPY_PY2_SRC=/path/to/renpy-7.8.7-sdk \
./scripts/populate-sdk.sh
```

Or use the default paths resolved by `scripts/unren-local.sh` (`RENPY_SDK_SOURCES` / `UNREN_LOCAL`).

Download full SDKs from [renpy.org](https://www.renpy.org/) when rebuilding trimmed `sdk/` slices. Once `git lfs pull` has populated `sdk/`, you rarely need the full trees.

**Release tarballs** (optional, for non-git users):

```bash
./scripts/package-sdk-release.sh
```

## Lineage

- [UnRen.bat](https://github.com/F95Sam/UnRen) — Sam
- [UnRen-Ultrahack](https://f95zone.to/threads/92717/) — VepsrP
- [UnRen-Linux.sh](https://github.com/zujik/UnRen-Linux.sh) — Troy Dallas
- [UnRen for Mac 0.9.0](https://f95zone.to/threads/16887/) — huchukato (Python 3 / unrpyc v2)
- [dikau-UnRen-sh](https://github.com/dikau/UnRen-sh) — cleaner bash structure (reference)

## Third-party tools

See **`THIRD_PARTY_LICENSES.md`** and **`NOTICE`** for full attribution.

| Tool | License |
|------|---------|
| [unrpyc](https://github.com/CensoredUsername/unrpyc) | MIT |
| [rpatool](https://codeberg.org/shiz/rpatool) | WTFPL |
| [UnRen-forall](https://github.com/Lurmel/UnRen-forall) staging | GPL-3.0 — `licenses/unren_forall.GPL-3.txt` |
| altrpatool (py3 port) | GPL-3 — `tools/altrpatool-py3/COPYING` |
| rpycCorrector (AON/SC4X, py3 port) | BSD-2-Clause — `licenses/rpyc_corrector.BSD-2-Clause.txt` |
| Ren'Py SDK slices | MIT + LGPL binaries — `sdk/*/LICENSE.txt` |

Origins and versions: `tools/SOURCES.md`, `manifest.json`, `docs/SOURCE_INVENTORY.md`.

## Legal notes

- **UnRen-Desktop** is **GPL-3.0** (v3 or later) — legal terms in `LICENSE`; attribution and lineage in `NOTICE`.
- Offline bundles that include GPL tools (forall, altrpatool) must ship under GPL-3.0.
- **altrpatool** and **UnRen-forall** staging are **GPL-3** — full text in `licenses/GPL-3.0.txt`.
- **rpycCorrector** is **BSD-2-Clause** — Anne O'nymous copyright preserved in source and `licenses/`.
- **Ren'Py SDK** runtime files include `LICENSE.txt` per slice; some binaries are LGPL.
- **Game content** remains copyrighted by game authors. UnRen only helps unpack/patch installs you already have for personal use.

At startup, `scripts/verify_compliance.py` audits `licenses/` against `manifest.json`.

This is practical open-source hygiene, not legal advice. If you redistribute a
custom build, include `LICENSE`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, and `docs/SOURCE_INVENTORY.md`.

## Decompile limits

unrpyc recovers most Ren'Py scripts, but **heavily customized games** (custom statements, layered images, game-specific pickles) may show:

- **Unknown AST node** warnings — custom `store.*` statements decompile as `pass # <<<COULD NOT DECOMPILE>>>` placeholders
- **Truncated screens** — empty `at transform:` blocks at end of file (UnRen auto-appends `pass` after decompile; see `patches/decompile-fixes/`)
- **Launch errors** after full decompile — broken `.rpy` takes precedence over `.rpyc`; run option **g** (applies fixes) or delete specific bad `.rpy` to fall back to bytecode

Game test notes and known titles: **`docs/TESTING.md`**.

## License

**GPL-3.0** (v3 or later) — full text in `LICENSE`. Project attribution and lineage in `NOTICE`.
Third-party components: `THIRD_PARTY_LICENSES.md`, `tools/SOURCES.md`.

Maintainer: **Kijuz** on [F95zone](https://f95zone.to/) · GitHub: [zujik](https://github.com/zujik)
