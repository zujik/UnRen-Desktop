# Third-Party Licenses

UnRen-Desktop bundles or invokes components from the projects below. When you
redistribute this repository or a release built from it, keep `LICENSE`,
`NOTICE`, this file, and per-component license files intact.

**This document is not legal advice.** It records what upstream authors published
and how UnRen-Desktop complies in good faith.

---

## UnRen-Desktop (this project)

**License:** MIT  
**Copyright:** (c) 2022–2026 Troy Dallas  
**Text:** `LICENSE`

UnRen-Desktop orchestration code (`UnRen.sh`, `unren/`, `scripts/`, `patches/`
authored for this repo, `docs/`, etc.) is under MIT unless noted otherwise.

---

## Lineage (ideas and prior ports)

| Project | Author | License (as published) | Notes |
|---------|--------|------------------------|-------|
| [UnRen.bat](https://github.com/F95Sam/UnRen) | Sam (F95Sam) | **Not declared** on GitHub | Community Windows batch tool; concepts and menu flow |
| [UnRen-Linux.sh](https://github.com/zujik/UnRen-Linux.sh) | Troy Dallas | **MIT** | Prior Linux port; renamed to UnRen-Desktop |
| [UnRen-Ultrahack](https://f95zone.to/threads/92717/) | VepsrP | Forum distribution | Extended Windows feature set |
| [UnRen for Mac 0.9.0](https://f95zone.to/threads/16887/) | huchukato | Forum distribution | Python 3 / unrpyc v2 reference |
| [UnRen-sh](https://github.com/dikau/UnRen-sh) | dikau | Unknown (repo unavailable) | Bash structure reference |

UnRen-Desktop is a new MIT work that credits these predecessors. It does not
claim their copyrights.

---

## Python tools (in `tools/`)

### unrpyc

| | |
|---|---|
| **Path** | `tools/unrpyc-py3/` |
| **Upstream** | https://github.com/CensoredUsername/unrpyc (v2.0.4 base) |
| **Authors** | Yuri K. Schlesner, CensoredUsername, Jackmcbarn, contributors |
| **License** | **MIT** (per-file headers) |
| **UnRen changes** | `PATCHES.md` — Ren'Py 8 type hints, legacy `_ast` codegen, etc. |

`decompiler/codegen.py` includes **BSD** terms (Armin Ronacher / Jinja heritage) in
its file header.

### rpatool

| | |
|---|---|
| **Path** | `tools/rpatool-py3/rpatool.py` |
| **Upstream** | https://codeberg.org/shiz/rpatool |
| **License** | **WTFPL v2** (Do What The Fuck You Want To Public License) |

### altrpatool

| | |
|---|---|
| **Path** | `tools/altrpatool-py3/altrpatool.py` |
| **Author** | JoeLurmel @ f95zone.to |
| **Origin** | Embedded in UnRen-forall; py3 port in UnRen-Desktop |
| **License** | **GNU GPL v3** |
| **Full text** | `tools/altrpatool-py3/COPYING` |

altrpatool is a **separate program** invoked by UnRen via `python3 altrpatool.py`.
It is not linked into MIT-licensed shell code. GPL source is included in this repo.

### rpycCorrector

| | |
|---|---|
| **Path** | `tools/rpyccorrect-py3/rpyccorrect.py` |
| **Original** | v1.04 by Anne O'nymous (AON/SC4X), 2019–2020 |
| **Forum** | [F95zone thread](https://f95zone.to/threads/rpyccorrector-1-04-rpyc-signature-corrector-formerly-sigcorrector.26320/) |
| **License** | **Not stated** in the original archive |
| **UnRen** | py3 port; copyright header preserved — see `tools/rpyccorrect-py3/README.md` |

### UnRen-forall staging scripts

| | |
|---|---|
| **Path** | `tools/forall/` |
| **Upstream** | https://github.com/Lurmel/UnRen-forall (tag `la_0.77-le_9.7.60-cu_9.7.80`) |
| **Author** | JoeLurmel / Lurmel |
| **License** | **Not SPDX-declared** on GitHub; altrpatool component is **GPL-3.0** |
| **Attribution** | `tools/forall/ATTRIBUTION.md` |

Scripts: `detect_rpa_ext.py`, `detect_archive.py`, `detect_rpyc_version.py`,
`wos_decrypt_all.py` — vendored with local patches noted in `ATTRIBUTION.md`.

### detect_renpy_version

| | |
|---|---|
| **Path** | `tools/detect-renpy-version/detect_renpy_version.py` |
| **Origin** | UnRen-forall embedded script |
| **License** | Same as forall staging (see above) |

---

## Ren'Py SDK runtime slices (`sdk/`)

| | |
|---|---|
| **Copyright** | (c) 2004–2026 Tom Rothamel and contributors |
| **License** | Mostly **MIT**; some bundled binaries (FFmpeg, SDL2, etc.) under **LGPL** |
| **Per-slice text** | `sdk/py3-8.5.3/LICENSE.txt`, `sdk/py2-7.8.7/LICENSE.txt`, `sdk/py2-6.99.14.3/LICENSE.txt`, `sdk/py2-5.6.7/LICENSE.txt` |
| **Official** | https://www.renpy.org/ · https://github.com/renpy/renpy/blob/master/LICENSE.txt |

When redistributing trimmed `sdk/` binaries from this repo:

1. Include the matching `sdk/*/LICENSE.txt`.
2. Do not strip copyright headers from Ren'Py source files.
3. Prefer pointing users to renpy.org for full SDK downloads when practical.

### py2 md5 stdlib shim

| | |
|---|---|
| **Path** | `sdk/stdlib-shims/py2/md5.py` (+ copies under `sdk/py2-6.99.14.3/.../python2.7/`) |
| **License** | **MIT** (UnRen-Desktop) |
| **Purpose** | Legacy `import md5` compatibility for py2 SDK-launched games |

---

## Compatibility matrix (can UnRen-Desktop stay MIT?)

| Component | License | Bundled how | OK with MIT project? |
|-----------|---------|-------------|----------------------|
| UnRen-Desktop shell/modules | MIT | — | Yes |
| unrpyc | MIT | Separate Python package | Yes |
| rpatool | WTFPL | Separate script | Yes |
| altrpatool | GPL-3 | Separate script + `COPYING` | Yes (aggregate; include GPL) |
| rpycCorrector | Unstated | Separate script + attribution | Attribute; no license conflict |
| forall scripts | Unstated / mixed | Separate scripts | Attribute; GPL applies to altrpatool only |
| Ren'Py SDK | MIT + LGPL binaries | Trimmed runtime tree + LICENSE.txt | Yes with LICENSE.txt included |

**Conclusion:** Keep **MIT** for UnRen-Desktop. Do **not** relicense the whole
project as GPL. Ship `COPYING` for altrpatool and preserve Ren'Py `LICENSE.txt`
files in release archives.

---

## Game content disclaimer

UnRen-Desktop is a **utility for unpacking and patching Ren'Py game installs you
already possess**. It does not grant rights to game assets, scripts, or
trademarks. Game copyrights remain with their respective authors and publishers.
Use only on copies you are entitled to modify for personal use.
