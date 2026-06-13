# UnRen-forall staging tools

Vendored from **UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80** (JoeLurmel / Lurmel).

- Upstream: https://github.com/Lurmel/UnRen-forall
- Forum: JoeLurmel @ f95zone.to

These copies are **staging** — wired into `unren/forall.sh`, `extract.sh`, and `decompile.sh` as-is for testing. Refactor or reimplement later; keep this attribution block.

| Script | Role in UnRen-Desktop |
|--------|------------------------|
| `detect_rpa_ext.py` | Discover archive extensions via Ren'Py handlers or RPA header scan |
| `detect_archive.py` | Per-file: standard RPA → rpatool, else altrpatool |
| `detect_rpyc_version.py` | Warn on RPC3 bytecode before decompile |
| `wos_decrypt_all.py` | Decrypt WOS-encrypted `.rpyc` when `renpy/wos_rpyc_loader.py` exists |

**Not from forall:** `rpycCorrector` (AON/SC4X v1.04), `detect_renpy_version` (separate dir), `altrpatool` (separate py3 port).

**Local patches (UnRen-Desktop only):**

- `wos_decrypt_all.py` — import `renpy.wos_rpyc_loader` from game root (`UNREN_APP`), not beside the script.
