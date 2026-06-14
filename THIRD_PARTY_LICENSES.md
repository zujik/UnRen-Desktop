# Third-Party Licenses

UnRen-Desktop bundles or invokes components from the projects below. When you
redistribute this repository or a release built from it, keep `LICENSE`,
`NOTICE`, `THIRD_PARTY_LICENSES.md`, `docs/SOURCE_INVENTORY.md`, and per-component
license files under `licenses/` intact.

**This document is not legal advice.** It records what upstream authors published
and how UnRen-Desktop complies in good faith.

---

## UnRen-Desktop (this project)

**License:** GNU GPL v3.0-only (GPL-3.0-only)  
**Copyright:** (c) 2022–2026 Kijuz (F95zone: Kijuz · GitHub: [zujik](https://github.com/zujik))  
**Text:** `LICENSE` (full GPL-3.0)

UnRen-Desktop orchestration code (`UnRen.sh`, `unren/`, `scripts/`, `patches/`
authored for this repo, `docs/`, etc.) is under **GPL-3.0** when distributed as
an offline bundle containing GPL-covered tools (UnRen-forall staging, altrpatool).

A future **download-on-first-run** bootstrap that ships only `UnRen.sh` and
fetches GPL tools at runtime still requires full attribution and license texts
for every fetched component — see `manifest.json` and `licenses/`.

---

## Lineage (ideas and prior ports)

| Project | Author | License (as published) | Notes |
|---------|--------|------------------------|-------|
| [UnRen.bat](https://github.com/F95Sam/UnRen) | Sam / Gideon (F95Sam) | **Not declared** on GitHub | Community Windows batch tool; concepts and menu flow |
| [UnRen-Linux.sh](https://github.com/zujik/UnRen-Linux.sh) | Troy Dallas | **MIT** | Prior Linux port; credited as lineage only |
| [UnRen-Ultrahack / UnRen-forall](https://f95zone.to/threads/92717/) | VepsrP → JoeLurmel | **GPL-3.0** (forall repo) | Extended Windows feature set |
| [UnRen for Mac 0.9.0](https://f95zone.to/threads/16887/) | huchukato | Forum distribution | Python 3 / unrpyc v2 reference |
| [UnRen-sh](https://github.com/dikau/UnRen-sh) | dikau | Unknown (repo unavailable) | Bash structure reference |

UnRen-Desktop credits these predecessors. It does not claim their copyrights.

---

## Python tools (in `tools/`)

### unrpyc

| | |
|---|---|
| **Path** | `tools/unrpyc-py3/` |
| **Upstream** | https://github.com/CensoredUsername/unrpyc (v2.0.4 base) |
| **Authors** | Yuri K. Schlesner, CensoredUsername, Jackmcbarn, contributors |
| **License** | **MIT** (per-file headers) |
| **License file** | `licenses/unrpyc.MIT.txt` |
| **UnRen changes** | `PATCHES.md` — Ren'Py 8 type hints, legacy `_ast` codegen, etc. |

`decompiler/codegen.py` includes **BSD** terms (Armin Ronacher / Jinja heritage) in
its file header.

### rpatool

| | |
|---|---|
| **Path** | `tools/rpatool-py3/rpatool.py` |
| **Upstream** | https://codeberg.org/shiz/rpatool |
| **License** | **WTFPL v2** (Do What The Fuck You Want To Public License) |
| **License file** | `licenses/rpatool.WTFPL.txt` |

### altrpatool

| | |
|---|---|
| **Path** | `tools/altrpatool-py3/altrpatool.py` |
| **Author** | JoeLurmel @ f95zone.to |
| **Origin** | Embedded in UnRen-forall; py3 port in UnRen-Desktop |
| **License** | **GNU GPL v3** |
| **Full text** | `tools/altrpatool-py3/COPYING`, `licenses/GPL-3.0.txt`, `licenses/altrpatool.GPL-3.txt` |

altrpatool is a **separate program** invoked by UnRen via `python3 altrpatool.py`.
GPL source and license text are included in this repo.

### rpycCorrector

| | |
|---|---|
| **Path** | `tools/rpyccorrect-py3/rpyccorrect.py` |
| **Original** | v1.04 by Anne O'nymous (AON/SC4X), 2019–2020 |
| **Forum** | [F95zone thread](https://f95zone.to/threads/rpyccorrector-1-04-rpyc-signature-corrector-formerly-sigcorrector.26320/) |
| **License** | **BSD-2-Clause** (copyright block in original distribution) |
| **License file** | `licenses/rpyc_corrector.BSD-2-Clause.txt` |
| **UnRen** | py3 port; full BSD-2-Clause header preserved in source |

### UnRen-forall staging scripts

| | |
|---|---|
| **Path** | `tools/forall/` |
| **Upstream** | https://github.com/Lurmel/UnRen-forall (tag `la_0.77-le_9.7.60-cu_9.7.80`) |
| **Author** | JoeLurmel / Lurmel |
| **License** | **GNU GPL v3** — https://github.com/Lurmel/UnRen-forall/blob/main/LICENSE |
| **License file** | `licenses/unren_forall.GPL-3.txt` |
| **Attribution** | `tools/forall/ATTRIBUTION.md` |

Scripts: `detect_rpa_ext.py`, `detect_archive.py`, `detect_rpyc_version.py`,
`wos_decrypt_all.py` — vendored with local patches noted in `ATTRIBUTION.md`.

### detect_renpy_version

| | |
|---|---|
| **Path** | `tools/detect-renpy-version/detect_renpy_version.py` |
| **Origin** | UnRen-forall embedded script |
| **License** | **GPL-3.0** (same as UnRen-forall) |

---

## Ren'Py SDK runtime slices (`sdk/`)

| | |
|---|---|
| **Copyright** | (c) 2004–2026 Tom Rothamel and contributors |
| **License** | Mostly **MIT**; some bundled binaries (FFmpeg, SDL2, etc.) under **LGPL** |
| **Per-slice text** | `sdk/py3-8.5.3/LICENSE.txt`, `sdk/py2-7.8.7/LICENSE.txt`, `sdk/py2-6.99.14.3/LICENSE.txt`, `sdk/py2-5.6.7/LICENSE.txt` |
| **Summary** | `licenses/renpy-sdk.MIT-LGPL.txt` |
| **Official** | https://www.renpy.org · https://github.com/renpy/renpy/blob/master/LICENSE.txt |

When redistributing trimmed `sdk/` binaries from this repo:

1. Include the matching `sdk/*/LICENSE.txt`.
2. Do not strip copyright headers from Ren'Py source files.
3. Prefer pointing users to renpy.org for full SDK downloads when practical.

### py2 md5 stdlib shim

| | |
|---|---|
| **Path** | `sdk/stdlib-shims/py2/md5.py` (+ copies under `sdk/py2-6.99.14.3/.../python2.7/`) |
| **License** | **GPL-3.0** (part of UnRen-Desktop; same as project) |
| **Purpose** | Legacy `import md5` compatibility for py2 SDK-launched games |

---

## Distribution models and GPL

| Model | What you ship | Project license impact |
|-------|---------------|------------------------|
| **Offline bundle** | Full `UnRen-Desktop` tree including GPL tools | Entire distribution **GPL-3.0** — use root `LICENSE` |
| **Bootstrap** | `UnRen.sh` only; downloads deps at runtime | Wrapper is GPL-3.0; fetched tools keep their own licenses |
| **Source repo** | Git clone with all vendored tools | **GPL-3.0** for the combined work |

**Why GPL-3.0 for UnRen-Desktop:** UnRen-forall and altrpatool are GPL-3.0.
Shipping them inside release archives makes the combined work a derivative
distribution under GPL copyleft rules.

---

## Runtime compliance audit

At startup, `UnRen.sh` runs `scripts/verify_compliance.py` (via `unren/compliance.sh`):

1. Parses `manifest.json` → `compliance_block` and `dependencies`.
2. Verifies each `expected_license_file` under `licenses/`.
3. For **rpycCorrector**, also checks the BSD-2-Clause header in `rpyccorrect.py`.
4. On missing or corrupt license files, prints a secure re-download notice and
   fetches from the **UnRen-Dependencies** mirror (`manifest.json` URLs).

Set `UNREN_STRICT_COMPLIANCE=1` to exit on audit failure. Set
`UNREN_MIRROR_DOWNLOAD=0` to skip network re-fetch.

---

## Documented upstream gaps

| Component | Status |
|-----------|--------|
| **UnRen.bat** (lineage) | No LICENSE on GitHub — inspiration only; not redistributed |
| **UnRen-Ultrahack** | Forum distribution — credited, not vendored |
| **UnRen for Mac** | Forum reference — credited |
| **dikau-UnRen-sh** | Repo 404 — structure reference only |
| **F95 forum patches** (unren-nsync, etc.) | Per-file author comments |

Provenance for downloads: `docs/SOURCE_INVENTORY.md`.

---

## Game content disclaimer

UnRen-Desktop is a **utility for unpacking and patching Ren'Py game installs you
already possess**. It does not grant rights to game assets, scripts, or
trademarks. Game copyrights remain with their respective authors and publishers.
Use only on copies you are entitled to modify for personal use.
