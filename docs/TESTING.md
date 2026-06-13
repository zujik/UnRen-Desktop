# Game test matrix

Run after toolchain or launcher changes. Copy **all** of `UnRen-Desktop/` into each game root (flat layout), then `./UnRen.sh`.

Ports merged 2026-06-13 — see `docs/PORT_FROM_WINDOWS.md`. **forall staging** (`tools/forall/`, Lurmel attribution) wired into extract + decompile. Slim deploy is **after** this matrix — see `docs/DEPLOY.md`.


## How to run each game

1. Flat-copy entire `UnRen-Desktop/` into game root (not `UnRen.sh` alone).
2. `./UnRen.sh` (or pass game path as arg).
3. Record: Ren'Py version, py2/py3, native Linux `lib/` or SDK fallback, options used, launch result.
4. Log row in **Per-game log** below.

**Default pipeline:** option **8** (extract + decompile + patches + launcher), then `./GameName.sh`.  
Use **9** when forum reports obfuscation / failed decompile. Use **c** first if thread mentions mangled RPYC signatures.

---

## Priority tiers

### Tier A — Smoke (do first)

| ID | Target | Why |
|----|--------|-----|
| A1 | Magic Shop 1.03 | **PASS** — py2 Win-only, SDK 6.99, RPA, Wayland |
| A2 | One native **py3** Linux build (`lib/py3-linux-*`) | No SDL override; game python path |
| A3 | One **py3 Win-only** (no Linux `lib/`) | SDK `py3-8.5.3` fallback |
| A4 | One **py2 Win-only** (no Linux `lib/`) | SDK `py2-6.99` or `py2-7.8.7` |
| A5 | One game with existing `.rpy` | Option **2** skips; option **0** clobbers stubs only |

### Tier B — Your planned buckets (≈5 each, fill names as you go)

| Bucket | Count | Layout signal | Primary options | Pass criteria |
|--------|-------|---------------|-----------------|---------------|
| **B1 Legacy oldest** | 5 | Ren'Py 5–6, very old `lib/` | 1, 2 or 8, g | Extract + decompile + launch via `py2-5.6.7` / `py2-6.99` |
| **B2 Problem thread** | many | forum “won’t unpack / decompile / launch” | 9, c, 1 | Fixes match tool (rpycCorrector, altrpatool, deobfuscate) |
| **B3 py2 + Linux `lib/`** | 5 | `lib/py2-linux-*` or `lib/linux-*` | 8, g | Native py2 python, SDL x11 if needed |
| **B4 py2, no Linux `lib/`** | 5 | Windows-only drop | 8, g | SDK slice launch |
| **B5 py3 + Linux `lib/`** | 5 | `lib/py3-linux-*` | 8, g | Native py3, no forced SDL |
| **B6 py3, no Linux `lib/`** | 5 | Win/Mac drop only | 8, g | SDK `py3-8.5.3` |

### Tier C — Feature-specific (any count; hunt from threads)

| ID | Feature under test | How to find games | Options |
|----|-------------------|-------------------|---------|
| C1 | **rpycCorrector** | Threads: altered `RPYC2_HEADER`, NBD/NKT encoding | **c** then 2 or **9** |
| C2 | **altrpatool** | Encrypted RPA, RWA-3.0, WOS, `.jas` / `.rpc` | **1** (fallback) |
| C3 | **deobfuscate** | unrpyc fails without `--try-harder` | **9** vs 8 |
| C4 | **detect_renpy_version** | Missing `script_version.rpy` | 8, g — check correct SDK picked |
| C5 | **Sync cleanup** | Games using Ren'Py sync / AppData saves | **n** then launch |
| C6 | **`.org` restore** | Games with `.rpa.org` backups from prior UnRen | **r** |
| C7 | **Multiple RPA** | 2+ archives in `game/` | **1** |
| C8 | **Pre-decompiled / stub `.rpy`** | F95 “already has .rpy” packs | **2** vs **0** |
| C9 | **SVAC / pickle5 RPA** | Newer encrypted archives (forum 2022+) | **1** with py3 rpatool path |

### Tier D — Environment (1–2 each is enough)

| ID | Condition | Notes |
|----|-----------|-------|
| D1 | Path with **spaces** | `My Game/` drag-drop |
| D2 | **Wayland** session (KDE) | py2 game → `GameName.sh` must not crash |
| D3 | **macOS `.app`** | Optional track: **m** quarantine, then g |
| D4 | **B2 subfolder** layout | `Game/UnRen/UnRen.sh` parent detection |

---

## Suggested minimum before refactor

| Must pass | Count |
|-----------|-------|
| Tier A | all 5 |
| B1 legacy | ≥3 of 5 |
| B4 + B6 Win-only | ≥3 each |
| B3 or B5 native Linux | ≥3 of one py generation |
| B2 problem | every game you care about from thread |
| C1 if you find a candidate | ≥1 |
| C2 if you find encrypted RPA | ≥1 |
| D2 Wayland + py2 | 1 (Magic Shop covers) |

Refactor only when the **must pass** rows are green or failures are documented as known limits.

---

## Bucket worksheets (copy per game)

### B1 — Legacy oldest (5)

```
#1  Game: __________  script_version: ___  lib layout: __________  Result: ___
#2  Game: __________  script_version: ___  lib layout: __________  Result: ___
#3  Game: __________  script_version: ___  lib layout: __________  Result: ___
#4  Game: __________  script_version: ___  lib layout: __________  Result: ___
#5  Game: __________  script_version: ___  lib layout: __________  Result: ___
```

### B2 — Problem thread

```
Game: __________  Thread/issue: __________  Options: ___  Result: ___  Tool fix: ___
```

### B3–B6 — py2/py3 × Linux lib yes/no (5 each)

Use columns: `Game | version | lib/py2-linux | lib/py3-linux | win-only | SDK used | 8/9 | launch`

---

## Anything else worth adding?

Your list is solid. These additions close common gaps:

1. **Ren'Py 7.x py2** — own bucket or ensure B3/B4 include a 7.4–7.7 game (`py2-7.8.7` slice, not 6.99).
2. **Option 9 vs 8** — at least one game where 8 fails decompile and 9 succeeds (proves rpycCorrector + deobfuscate chain).
3. **Skip-existing `.rpy`** — one game where option 2 must not overwrite good sources (regression for smart skip).
4. **Encrypted / non-standard archives** — even one `.jas` or RWA game validates altrpatool port.
5. **macOS track** — separate small list if you have `.app` builds (quarantine **m**); can run after Linux matrix.
6. **Re-run Magic Shop** after each major patch — cheap regression anchor.

You do **not** need 5× everything before first upload to yourself; hit **Tier A + must pass** first, then widen buckets as you find downloads.

---

## Original quick matrix (kept for reference)

| # | Game | `script_version` | Layout | Options | Launch | Notes |
|---|------|------------------|--------|---------|--------|-------|
| 1 | Magic Shop 1.03 | 6.18 | Win-only, SDK py2-6.99 | 8/9, 0, 1 | g | **PASS** |
| 2 | _(py3 native Linux)_ | 8+ | `lib/py3-linux-*` | 8, g | g | Tier A2 |
| 3 | _(py3 Win-only)_ | 8+ | no Linux lib | 8, g | g | Tier A3 |
| 4 | _(Ren'Py 7 py2)_ | 7.x | varies | 8, g | g | Tier A4 / B3/B4 |
| 5 | _(pre-decompiled)_ | any | existing `.rpy` | 2 vs 0 | — | Tier A5 |

## Per-game log

```
Date       Game                 Bucket  Result   Issue / fix
2026-06-13 Magic Shop 1.03      A1      PASS     rpatool py3, SDL x11, PYTHONHOME SDK-first
2026-06-14 Innocent Witches     B2      FAIL/LAUNCH  **Decompile/extract/stubs:** FAIL (custom AST, broken plot). **Vanilla Linux (confirmed):** fresh unzip → flat-copy UnRen → **3–6** → **g** — launches, language/terms flow, main menu, start game. No options 1/2/8. Crash-report prompt on first run is normal.
```

### Decompile warning noise

During decompile, UnRen **summarizes** repeated `Unknown AST node`, custom-displayable, and **Ren'Py 6/7 vs unrpyc-8 version** notices instead of printing each one. Real errors (tracebacks, failed decompile, non-zero exit) are still shown. Game Ren'Py version is read from `game/script_version.txt` when present.

Ren'Py **7** games on a **py3 SDK fallback** (no populated `py2-7.8.7` lib) need `fix-py2-print.py` after decompile (`print x` → `print(x)`). Run **g** to apply fixes and regenerate the launcher with correct `py2` SDK order.

Custom games (e.g. Innocent Witches) register dozens of `store.*` statement types unrpyc cannot reconstruct. Dialogue and standard Ren'Py still decompile; custom lines become `pass # <<<COULD NOT DECOMPILE>>>` comments.

unrpyc may also substitute **style names** for custom screen keywords (`imagetext_button` instead of `imagetextbutton`). UnRen fixes that via `fix-sl-keywords.py` on decompile/launch.

After decompile, UnRen runs **post-fixes** (`patches/decompile-fixes/`) for empty trailing `at transform:` blocks and known broken files. Re-run option **g** to apply fixes before launch without re-decompiling.

## Quick commands

```bash
./UnRen.sh /path/to/GameFolder   # option 8 = full pipeline + launcher
./GameName.sh                    # launch after option g/8/9
SDL_VIDEODRIVER=wayland ./GameName.sh   # py3 native Linux only
```
