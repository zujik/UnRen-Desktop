# Game test matrix

Run after toolchain or launcher changes. Copy flat UnRen-Desktop into each game root, then `./UnRen.sh`.

Ports merged 2026-06-13 (rpycCorrector, altrpatool, detect_renpy_version, sync/org, mac quarantine opt-in). See `docs/PORT_FROM_WINDOWS.md`.

| # | Game | `script_version` | Layout | Options | Launch | Notes |
|---|------|------------------|--------|---------|--------|-------|
| 1 | Magic Shop 1.03 | 6.18 | Win-only, SDK py2-6.99 | 8/9, 0, 1 | g | py2, RPA, Wayland/SDL — **pass** |
| 2 | _(py3 native Linux)_ | 8+ | `lib/py3-linux-*` | 8, g | g | No SDL override |
| 3 | _(py3 Win-only)_ | 8+ | SDK py3-8.5.3 | 8, g | g | SDK fallback |
| 4 | _(Ren'Py 7)_ | 7.x | varies | 2, g | g | py2-7.8.7 slice |
| 5 | _(pre-decompiled)_ | any | existing `.rpy` | 2 vs 0 | — | Skip vs clobber |

## Per-game log

```
Date       Game                 Result   Issue / fix
2026-06-13 Magic Shop 1.03      PASS     rpatool py3, SDL x11 override, PYTHONHOME SDK-first
```

## Quick commands

```bash
./UnRen.sh /path/to/GameFolder   # option 8 = full pipeline + launcher
./GameName.sh                    # launch after option g/8/9
SDL_VIDEODRIVER=wayland ./GameName.sh   # only for py3 native Linux builds
```
