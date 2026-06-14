# Post-decompile fixes

UnRen runs these automatically after decompile and before launch.

## Generic (all games)

- `tools/decompile-fixes/run-all.sh` — POSIX entry used by `GameName.sh` launchers (`/bin/sh` safe).
- `tools/decompile-fixes/fix-atl-tails.py` — empty trailing blocks (`at transform:`, `image foo:`, `show …:`, `camera:`, etc.).
- `tools/decompile-fixes/fix-sl-keywords.py` — restores SL keywords (`imagetext_button` → `imagetextbutton`, etc.).

## Per-game hooks

Add `patches/decompile-fixes/<slug>.sh` with a `unren_decompile_fix_<slug>()` function. `unren/decompile-fixes.sh` sources all patch files, then calls the matching hook when the game is detected.

| Game | Detector | Fixes (`tools/decompile-fixes/`) |
|------|----------|----------------------------------|
| Innocent Witches | exe / folder / `build.name` | see below — **KNOWN LIMIT: not playable after full extract+decompile** |

Innocent Witches hooks: `fix-sonya-store.py`, `fix-achievements-init.py`, `fix-spell-cast-anims.py`, `fix-community-tl.py`, `fix-tutorial-settings.py`, `fix-memories-scopes.py`, `fix-live2d-tails.py`, `fix-layered-images.py`, `fix-missing-menus.py`, `fix-iw-runtime-stubs.py`, `fix-main-menu.py`, `fix-assistant-actions.py`, `fix-game-menu.py`, `fix-characters.py`, truncated `credits/credits.rpy`.

**Innocent Witches — documented exception (menu-guarded).** Sad Crab ships dozens of custom `store.*` AST node types (`DefinePersonStatement`, `DynamicStatement`, `LayeredImageStatement`, `RawMenu`, …). Extract + decompile (options **1**, **2**, **8**, **9**) have been broken for years and are unlikely to be fixed while the game relies on custom Ren'Py internals. Full decompile leaves ~90k+ `COULD NOT DECOMPILE` lines, drops modules, truncates files, and breaks gameplay even after post-fix stubs.

**Supported workflow (Linux play):** fresh unzip → flat-copy UnRen → options **3–6** (or **7**) → **g**. UnRen auto-detects this title and disables **1/2/0/8/9/c** in the menu. **Confirmed 2026-06-14:** language picker, terms, main menu, and new game start all work. Crash-report prompt on first run is normal.

**Not supported:** option **1** (extract) → **8** (decompile) → **g** — remains a FAIL for end-to-end play regardless of post-fix hooks.

Re-decompile experiment (optional): flat-copy UnRen → option **8** → generic + IW hooks → **g**. Patches are idempotent. `UNREN_IW_FIXES=1` forces IW stubs when decompiled `.rpy` is already present.

These are **launchability** repairs, not full source recovery. For complete scripts, keep original `.rpyc` or restore from backup.
