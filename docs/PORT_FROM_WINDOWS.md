# Port / merge audit

Reference Windows spec (archived): `../../_archive/unren-legacy/UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80/`

## Ported (2026-06-13)

| Feature | Menu | Implementation |
|---------|------|----------------|
| rpycCorrector | **c**, option **9** pre-step | `tools/rpyccorrect-py3/` — from AON/SC4X v1.04, **not** in forall |
| altrpatool (JAS/RWA/SVAC) | option **1** fallback | `tools/altrpatool-py3/` — JoeLurmel / forall embed |
| detect_renpy_version | automatic | `tools/detect-renpy-version/` + `sdk-resolve.sh` |
| detect_rpa_ext + detect_archive | option **1** | `tools/forall/` — extension scan + per-file rpatool/altrpatool pick |
| detect_rpyc_version | options **2**, **8**, **9** | `tools/forall/` — RPC3 warning before decompile |
| wos_decrypt_all | options **2**, **8**, **9** | `tools/forall/` — when `renpy/wos_rpyc_loader.py` present |
| Sync folder cleanup | **n** | `unren/extras.sh` → `unren-nsync.rpy` |
| `.org` restore | **r** | `unren/extras.sh` |
| macOS quarantine | **m** (macOS only, opt-in) | `unren/mac.sh` — removed from auto-resolve |
| SDK download helper | `scripts/download-sdk.sh` | borrows F.Rvv3 / rpmac patterns |
| rpmac reference | — | `scripts/reference/rpmac.sh` (attributed, not merged) |

## Skipped / later

| Feature | Notes |
|---------|-------|
| UnRen 0.9.0 (huchukato) | Behind UnRen-Desktop; deobfuscate identical |
| dikau-UnRen-sh | Ancestor only; archived at `../../_archive/unren-legacy/dikau-UnRen-sh/` |
| `.org` delete | Windows opt **s** — low priority |
| Multi-option chains (`72k1`) | Power-user; 8/9 cover most |
| MC rename patch | forall launcher |
| Full rpmac Mac repackaging | Different job than Linux play-in-place |

## rpycCorrector source

Use **`rpycCorrector_1.04`** from `_archive/unren-legacy/misc/` — forall `.bat` does not embed it.

## Attribution

- **F.Rvv3** — `rpmac.sh` version detect + SDK download (f95zone thread 287097)
- **JoeLurmel / Lurmel** — [UnRen-forall](https://github.com/Lurmel/UnRen-forall) (`la_0.77-le_9.7.60-cu_9.7.80`): altrpatool, forall detect scripts, wos_decrypt, unren-nsync patch
- **AON/SC4X** — rpycCorrector 1.04

See `tools/SOURCES.md` for paths.
