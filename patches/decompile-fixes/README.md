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
| Innocent Witches | `Innocent Witches.exe` / `Innocent_Witches.exe` | `fix-sonya-store.py`, `fix-achievements-init.py`, `fix-spell-cast-anims.py`, `fix-community-tl.py`, `fix-tutorial-settings.py`, truncated `credits/credits.rpy` |

Re-decompile workflow: flat-copy UnRen → option **8** (decompile) → generic fixes run automatically → Innocent Witches hook runs if detected → option **g** (launch) re-runs fixes before start. Patches are idempotent (skip if marker already present).

These are **launchability** repairs, not full source recovery. For complete scripts, keep original `.rpyc` or restore from backup.
