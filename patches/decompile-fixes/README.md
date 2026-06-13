# Post-decompile fixes

UnRen runs these automatically after decompile and before launch.

## Generic

- `tools/decompile-fixes/run-all.sh` — POSIX entry used by `GameName.sh` launchers (`/bin/sh` safe).
- `tools/decompile-fixes/fix-atl-tails.py` — empty trailing blocks (`at transform:`, `image foo:`, `show …:`, etc.).
- `tools/decompile-fixes/fix-sl-keywords.py` — restores SL keywords (`imagetext_button` → `imagetextbutton`, etc.).

## Per-game hooks

Add `patches/decompile-fixes/<slug>.sh` with a `unren_decompile_fix_<slug>()` function, then detect the game in `unren/decompile-fixes.sh`.

| Game | Detector | Fix |
|------|----------|-----|
| Innocent Witches | `Innocent Witches.exe` / `Innocent_Witches.exe` | Truncated `game/credits/credits.rpy` → minimal `exit_credits` stub |

These are **launchability** repairs, not full source recovery. For complete scripts, keep original `.rpyc` or restore from backup.
