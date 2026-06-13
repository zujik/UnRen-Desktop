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
| Innocent Witches | `Innocent Witches.exe` / `Innocent_Witches.exe` | see below — **not fully launchable after full decompile** |

Innocent Witches hooks: `fix-sonya-store.py`, `fix-achievements-init.py`, `fix-spell-cast-anims.py`, `fix-community-tl.py`, `fix-tutorial-settings.py`, `fix-memories-scopes.py`, `fix-live2d-tails.py`, `fix-layered-images.py`, `fix-missing-menus.py`, `fix-iw-runtime-stubs.py`, `fix-main-menu.py`, `fix-assistant-actions.py`, `fix-game-menu.py`, `fix-characters.py`, truncated `credits/credits.rpy`.

**Innocent Witches is a special case — treat as FAIL for full decompile (option 8).** Sad Crab ships dozens of custom `store.*` AST node types (`DefinePersonStatement`, `DynamicStatement`, `LayeredImageStatement`, `RawMenu`, …). Full decompile leaves ~90k+ `COULD NOT DECOMPILE` lines, drops whole modules (`scripts/loadsave.rpy`), truncates files (`menus/loadsave.rpy`), and loses all 54 `define person` blocks in `persons.rpy`. Post-fix stubs can reach menus and early plot but gameplay remains broken (e.g. `tutorial.complete_item` on decompiled `main.rpy`).

**Recommended (vanilla play on Linux):** unzip fresh game → flat-copy UnRen → options **3–6** (or **7**) → **g**. Do **not** run options 1, 2, or 8. **Confirmed 2026-06-14:** language picker, terms, main menu, and new game start all work. Launch does **not** apply IW decompile stubs unless decompiled `.rpy` with `COULD NOT DECOMPILE` markers is already present (`UNREN_IW_FIXES=1` forces them).

**Decompile experiment (not playable end-to-end):** option **1** (extract RPA) → option **8** (decompile) → **g**. Option 1 again after extract = no archives (`.rpa.bak`) — expected.

Re-decompile workflow: flat-copy UnRen → option **8** (decompile) → generic fixes run automatically → Innocent Witches hook runs if detected → option **g** (launch) re-runs fixes before start. Patches are idempotent (skip if marker already present).

These are **launchability** repairs, not full source recovery. For complete scripts, keep original `.rpyc` or restore from backup.
