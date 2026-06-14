# Windows feature parity

This document records which **UnRen-forall** / **UnRen.bat** features are implemented in UnRen-Desktop and where they live in the tree.

Reference Windows bundle: [UnRen-forall](https://github.com/Lurmel/UnRen-forall) tag `la_0.77-le_9.7.60-cu_9.7.80`.

## Implemented

| Feature | Menu | Implementation |
|---------|------|----------------|
| rpycCorrector | **c**, option **9** pre-step | `tools/rpyccorrect-py3/` — AON/SC4X v1.04 (separate from forall) |
| altrpatool (JAS/RWA/SVAC) | option **1** fallback | `tools/altrpatool-py3/` — JoeLurmel / forall embed |
| detect_renpy_version | automatic | `tools/detect-renpy-version/` + `sdk-resolve.sh` |
| detect_rpa_ext + detect_archive | option **1** | `tools/forall/` — extension scan + per-file rpatool/altrpatool pick |
| detect_rpyc_version | options **2**, **8**, **9** | `tools/forall/` — RPC3 warning before decompile |
| wos_decrypt_all | options **2**, **8**, **9** | `tools/forall/` — when `renpy/wos_rpyc_loader.py` present |
| Sync folder cleanup | **n** | `unren/extras.sh` → `unren-nsync.rpy` |
| `.org` restore | **r** | `unren/extras.sh` |
| macOS quarantine | **m** (macOS only, opt-in) | `unren/mac.sh` |
| SDK download helper | `scripts/download-sdk.sh` | Ren'Py SDK fetch for `populate-sdk.sh` |

## Not implemented

| Feature | Notes |
|---------|-------|
| UnRen 0.9.0 (huchukato) | Superseded; deobfuscate path covered by option **9** |
| dikau-UnRen-sh | Bash structure reference only — [dikau/UnRen-sh](https://github.com/dikau/UnRen-sh) |
| `.org` delete | Windows option **s** — not ported |
| Multi-option chains (`72k1`) | Options **8** / **9** cover the common cases |
| MC rename patch | forall launcher feature |
| Full rpmac Mac repackaging | Different scope than Linux play-in-place |

## rpycCorrector source

rpycCorrector is **not** embedded in UnRen-forall `.bat` files. Obtain v1.04 from the [F95 forum thread](https://f95zone.to/threads/rpyccorrector-1-04-rpyc-signature-corrector-formerly-sigcorrector.26320/). UnRen-Desktop ships a py3 port at `tools/rpyccorrect-py3/`.

## Attribution

- **F.Rvv3** — SDK download patterns (f95zone thread 287097); reference at `scripts/reference/rpmac.sh`
- **JoeLurmel / Lurmel** — [UnRen-forall](https://github.com/Lurmel/UnRen-forall): altrpatool, forall detect scripts, wos_decrypt, unren-nsync patch
- **AON/SC4X** — rpycCorrector 1.04

See `tools/SOURCES.md` for paths and upstream URLs.
