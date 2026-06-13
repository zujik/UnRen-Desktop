# Post-decompile fixes

UnRen runs these automatically after decompile and before launch.

## Generic

- `tools/decompile-fixes/fix-atl-tails.py` — appends `pass` to `.rpy` files that end with an empty block (`at transform:`, `image foo:`, screen widgets, etc.).

## Per-game hooks

Add `patches/decompile-fixes/<slug>.sh` with a `unren_decompile_fix_<slug>()` function, then detect the game in `unren/decompile-fixes.sh`.

| Game | Detector | Fix |
|------|----------|-----|
| Innocent Witches | `Innocent Witches.exe` / `Innocent_Witches.exe` | Truncated `game/credits/credits.rpy` → minimal `exit_credits` stub |

These are **launchability** repairs, not full source recovery. For complete scripts, keep original `.rpyc` or restore from backup.
