# Game test matrix

Run after toolchain or launcher changes. Copy **all** of `UnRen-Desktop/` into each game root (flat layout), then `./UnRen.sh`.

Branch **`rename-refactor`** — Linux matrix **complete** (2026-06-14). See **Per-game log** below.

## How to run each game

1. Flat-copy entire `UnRen-Desktop/` into game root (not `UnRen.sh` alone).
2. `./UnRen.sh` (or pass game path as arg).
3. Record: Ren'Py version, py2/py3, native Linux `lib/` or SDK fallback, options used, launch result.

**Default pipeline:** option **8** (extract + decompile + patches + launcher), then `./GameName.sh`.  
Use **9** when forum reports obfuscation / failed decompile. Use **c** first if thread mentions mangled RPYC signatures.

**RPC3 games (Ren'Py 6 zlib bytecode):** **1** → patches **3–6** → **8** or **g** — never **2** / **0** / **9** / **c**. Stale decompiled `.rpy` is auto-removed on launch.

**Innocent Witches (known exception):** fresh unzip → patches **3–6** → **g** only. Menu auto-disables **1** / **2** / **0** / **8** / **9** / **c**. See [Known limits](#known-limits).

---

## Matrix status (2026-06-14)

| Bucket | Target | Result |
|--------|--------|--------|
| Tier A smoke | 5/5 | **PASS** (see regression anchors) |
| Py2/Py3 modern Win + Win/Linux | 9 | **9/9 PASS** |
| Py3 Win-only | 5 | **5/5 PASS** |
| Py3 Win + Linux native | 6 | **6/6 PASS** |
| Py2 Win-only (SDK / RPC3) | 5 | **5/5 PASS** |
| Py2 Win + Linux legacy | 5 | **5/5 PASS** |
| Known limits | Innocent Witches | **GUARDED** — launch OK, extract/decompile FAIL |

**Total: 29 PASS, 1 documented exception.**

### Regression anchors (re-test after toolchain changes)

Extract fresh from zip, flat-copy UnRen, option **8** or **g**:

| Game | Why |
|------|-----|
| **Magic Shop 1.03** | py2 Win-only, SDK `py2-6.99.14.3`, RPC3, Wayland/SDL |
| **Hollow** | py3 native Linux `lib/py3-linux-x86_64` |

---

## Known limits

### Innocent Witches (Sad Crab)

**Status:** Menu-guarded known exception — **playable on Linux**, **not fixable** for full extract/decompile.

Sad Crab uses dozens of custom `store.*` AST statement types that unrpyc cannot reconstruct. Options **1** (extract) and **2** / **8** (decompile) fail or produce unusable sources (~90k+ `COULD NOT DECOMPILE` lines, truncated modules, broken plot). This has been broken for years and is a developer/game limitation, not an UnRen regression.

**Supported workflow:**

```
fresh unzip → flat-copy UnRen → 3–6 (or 7) → g
```

**Confirmed:** language picker, terms, main menu, new game start. First-run crash-report prompt is normal.

**Guard:** UnRen detects Innocent Witches (exe name, folder name, `build.name`) and hides/disables **1**, **2**, **0**, **8**, **9**, **c**. Option **g** installs launcher and runs from shipped `.rpyc`.

Details: `patches/decompile-fixes/README.md`.

### RPC3 bytecode (Ren'Py 6)

Games with zlib RPC3 `.rpyc` (e.g. Demon Master Chris, Medicine Woman, Magic Shop, Planet Stronghold): decompile is unreliable. Options **2** / **0** / **9** / **c** disabled; launch uses `.rpyc`. Leftover decompiled `.rpy` removed automatically on **g** / **8**.

---

## Per-game log

```
Date       Game                              Bucket           Result   Notes
2026-06-13 Magic Shop 1.03                   A1 / py2 SDK     PASS     RPC3; py2-6.99; SDL x11; regression anchor
2026-06-14 Hollow                            B5               PASS     py3 native Linux; regression anchor
2026-06-14 Deviant Brew                      B5               PASS     stale launcher placeholders fixed
2026-06-14 Rediscovering Us                  B5               PASS     rpycCorrector exit 1 on R8 = harmless
2026-06-14 Planet Stronghold                 B4 / RPC3        PASS     md5.py shim for py2 SDK
2026-06-14 Demon Master Chris                B4 / RPC3        PASS
2026-06-14 The Medicine Woman                B4 / RPC3        PASS     read-only zip perms; legacy lib/
2026-06-14 Innocent Witches                  B2               GUARD    extract+decompile FAIL; 3-6+g PASS
```

### Py2/Py3 — Windows / Windows + Linux

| Game | Result | Notes |
|------|--------|-------|
| City of Broken Dreamers | PASS | patched or unpatched |
| Being a DIK | PASS | patched or unpatched |
| Ecchi Sensei | PASS | patched or unpatched |
| Divine Adventure Rebirth | PASS | patched or unpatched |
| Innocent Witches | **GUARD** | see [Known limits](#innocent-witches-sad-crab) |
| Rogue-like: Evolution | PASS | patched or unpatched |
| One Week Away | PASS | patched or unpatched |
| Undercover with Nora | PASS | patched or unpatched |
| The Invisible Pervert | PASS | patched or unpatched |

### Py3 — Windows only

| Game | Result |
|------|--------|
| Furry Superstar | PASS |
| Night of Love | PASS |
| I was Reborn in a Fantasy World… | PASS |
| LeafFlow | PASS |
| Eternal Storm | PASS |

### Py3 — Windows + Linux native

| Game | Result |
|------|--------|
| Obsessed Lucy | PASS |
| Love & Sex: Second Base — Shawn's Story | PASS |
| Hollow | PASS |
| Deviant Brew | PASS |
| With Great Pleasure | PASS |
| Rediscovering Us | PASS |

### Py2 — Windows only (SDK / RPC3)

| Game | Result |
|------|--------|
| Planet Stronghold | PASS |
| Sakura Shrine Girls | PASS |
| Demon Master Chris | PASS |
| The Medicine Woman | PASS |
| Demon on a Starship & Demon in the Flesh | PASS |

### Py2 — Windows + Linux legacy

| Game | Result |
|------|--------|
| Gargoyles, The beast and the Bitch | PASS |
| Jane, The Office Slut | PASS |
| Something's in the Air | PASS |
| Date Ariane | PASS |
| Superspy Steve | PASS |

---

## Priority tiers (reference)

### Tier A — Smoke

| ID | Target | Status |
|----|--------|--------|
| A1 | Magic Shop 1.03 | **PASS** |
| A2 | Hollow (py3 native Linux) | **PASS** |
| A3 | py3 Win-only (e.g. Furry Superstar) | **PASS** |
| A4 | py2 Win-only SDK (e.g. Planet Stronghold) | **PASS** |
| A5 | pre-decompiled `.rpy` / option 0 vs 2 | covered in RPC3 cleanup |

### Tier B — Buckets

| Bucket | Status |
|--------|--------|
| B1 Legacy oldest | covered by py2 legacy + Magic Shop |
| B2 Problem thread | Innocent Witches documented; others PASS |
| B3 py2 + Linux `lib/` | **5/5 PASS** |
| B4 py2 Win-only SDK | **5/5 PASS** |
| B5 py3 + Linux `lib/` | **6/6 PASS** |
| B6 py3 Win-only | **5/5 PASS** |

### Tier C — Feature-specific (optional future)

| ID | Feature | Status |
|----|---------|--------|
| C1 | rpycCorrector | tested; R8 false positive = harmless |
| C2 | altrpatool / encrypted RPA | not in this matrix |
| C3 | deobfuscate (9 vs 8) | not required for PASS set |
| C4–C9 | see prior list | defer |

### Tier D — Environment

| ID | Status |
|----|--------|
| D1 paths with spaces | Magic Shop, Planet Stronghold |
| D2 Wayland + py2 SDL x11 | Magic Shop, Medicine Woman |
| D3 macOS | not in Linux matrix |
| D4 B2 subfolder layout | supported |

---

## Decompile notes

During decompile, UnRen **summarizes** repeated `Unknown AST node`, custom-displayable, and **Ren'Py 6/7 vs unrpyc-8 version** notices. Real errors (tracebacks, failed decompile) are still shown.

Ren'Py **7** games on **py3 SDK fallback** need `fix-py2-print.py` after decompile. Run **g** before launch.

**rpycCorrector** on Ren'Py 8+ games may print `unknown encoding` and exit 1 — harmless; files are standard RPYC2, nothing altered.

Post-decompile fixes: `patches/decompile-fixes/`, `tools/decompile-fixes/`. Re-run **g** to apply without re-decompiling.

---

## Quick commands

```bash
./UnRen.sh /path/to/GameFolder   # option 8 = full pipeline + launcher
./GameName.sh                    # launch after option g/8/9
SDL_VIDEODRIVER=wayland ./GameName.sh   # py3 native Linux only
```

---

## Next steps (project)

1. Commit `rename-refactor` (RPC3 cleanup, md5 shim, IW guard, launcher fixes).
2. Refactor layout: game folder + `UnRen.sh` only for transfer.
3. Slim deploy: `UnRen.sh` pulls tools/sdk from GitHub as needed.

See `docs/DEPLOY.md` when starting slim packaging.
