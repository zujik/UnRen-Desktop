# Source Inventory & Dependency Provenance

This inventory is maintained for license compliance and bootstrap auditing. Because
this tool utilizes a **download-on-first-run** architecture (alongside optional
offline bundles), third-party components may be fetched dynamically at runtime from
our managed vendor mirror repository and are subject to their own licenses.

**Maintainer:** Kijuz · GitHub: [zujik](https://github.com/zujik)

| Component | Upstream Source / Download URL | License | Role / Notes |
| :--- | :--- | :--- | :--- |
| **unrpyc 2.0.4** | https://github.com/CensoredUsername/unrpyc | MIT | Ren'Py decompiler |
| **rpatool** | https://codeberg.org/shiz/rpatool | WTFPL | RPA archive extractor |
| **UnRen-forall la_0.77** | https://github.com/Lurmel/UnRen-forall · [F95 thread](https://f95zone.to/threads/unrengui-unren-forall-v9-4-unren-powershell-forall-v9-4-unren-old.92717/post-17110063) | GPL-3.0 | Modern Ren'Py toolkit extension (JoeLurmel / Lurmel) |
| **rpycCorrector 1.04** | [F95 thread 26320](https://f95zone.to/threads/rpyccorrector-1-04-rpyc-signature-corrector-formerly-sigcorrector.26320/) | BSD-2-Clause | RPYC signature corrector (Anne O'nymous / AON/SC4X) |
| **altrpatool** | Embedded in UnRen-forall | GPL-3.0 | Modified rpatool variant by JoeLurmel; lineage via VepsrP → Sam/Gideon |
| **Ren'Py SDK 8.5.3** | https://www.renpy.org/dl/8.5.3/renpy-8.5.3-sdk.tar.bz2 | MIT + LGPL | Modern runtime compatibility layers |
| **Ren'Py SDK 7.8.7** | https://www.renpy.org/dl/7.8.7/renpy-7.8.7-sdk.tar.bz2 | MIT + LGPL | Legacy runtime compatibility layers |
| **Ren'Py SDK 6.99.14.3** | https://www.renpy.org/dl/6.99.14/renpy-6.99.14-sdk.tar.bz2 (trimmed slice) | MIT + LGPL | Ren'Py 6.x runtime slice |
| **Ren'Py SDK 5.6.7** | Ren'Py 5.x archive (trimmed slice in `sdk/py2-5.6.7/`) | MIT + LGPL | Vintage runtime compatibility layers |
| **UnRen.bat / Sam** | https://github.com/F95Sam/UnRen · [F95 thread](https://f95zone.to/threads/unren-bat-v1-0-11d-rpa-extractor-rpyc-decompiler-console-developer-menu-enabler.3083/) | None stated | Original Windows batch logic inspiration (Sam / Gideon) |
| **UnRen-Linux.sh** | https://github.com/zujik/UnRen-Linux.sh | MIT (prior port) | Earlier Linux wrapper by Troy Dallas; superseded by UnRen-Desktop |
| **UnRen-Desktop** | https://github.com/zujik/UnRen-Desktop | GPL-3.0 | This wrapper / orchestrator (`UnRen.sh`, `unren/`, release bundles) |

## Mirror archive (bootstrap)

Runtime downloads and license re-fetch use the planned **UnRen-Dependencies** mirror:

- https://github.com/zujik/UnRen-Dependencies

See `manifest.json` → `dependencies` for per-component `download_url` and
`license_download_url` paths. Local copies live under `licenses/`.

## Audit log

| Date | Auditor | Notes |
|------|---------|-------|
| 2026-06-13 | Kijuz | Verified UnRen-forall GPL-3.0 (`Lurmel/UnRen-forall` LICENSE); rpycCorrector BSD-2-Clause (F95 header); project relicensed GPL-3.0 for offline bundle distribution |
