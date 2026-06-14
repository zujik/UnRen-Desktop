# UnRen-forall staging tools

Vendored from **UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80** (JoeLurmel / Lurmel).

- Upstream: https://github.com/Lurmel/UnRen-forall
- Forum: JoeLurmel @ f95zone.to

These copies are **staging** — wired into `unren/forall.sh`, `extract.sh`, and `decompile.sh` as-is for testing. Refactor or reimplement later; keep this attribution block.

**License:** **GNU GPL v3** — verified at https://github.com/Lurmel/UnRen-forall/blob/main/LICENSE (Copyright 2025 JoeLurmel). Full text: `licenses/unren_forall.GPL-3.txt` and `licenses/GPL-3.0.txt`. The embedded **altrpatool** component is also **GPL-3.0** (`tools/altrpatool-py3/COPYING`). See `THIRD_PARTY_LICENSES.md` and `docs/SOURCE_INVENTORY.md`.

| Script | Role in UnRen-Desktop |
|--------|------------------------|
| `detect_rpa_ext.py` | Discover archive extensions via Ren'Py handlers or RPA header scan |
| `detect_archive.py` | Per-file: standard RPA → rpatool, else altrpatool |
| `detect_rpyc_version.py` | Warn on RPC3 bytecode before decompile |
| `wos_decrypt_all.py` | Decrypt WOS-encrypted `.rpyc` when `renpy/wos_rpyc_loader.py` exists |

**Not from forall:** `rpycCorrector` (AON/SC4X v1.04), `detect_renpy_version` (separate dir), `altrpatool` (separate py3 port).

**Local patches (UnRen-Desktop only):**

- `wos_decrypt_all.py` — import `renpy.wos_rpyc_loader` from game root (`UNREN_APP`), not beside the script.
- `detect_rpyc_version.py` — probe `scripts.rpa` (and other `.rpa`) plus any loose `.rpyc` when standard candidates are not on disk yet.
