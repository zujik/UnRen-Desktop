# Ported tool sources

| Tool | Path | Origin | Notes |
|------|------|--------|-------|
| rpycCorrector | `tools/rpyccorrect-py3/` | AON/SC4X v1.04 (`_archive/.../rpycCorrector_1.04`) | py3 port; menu **c** / option **9** |
| altrpatool | `tools/altrpatool-py3/` | JoeLurmel @ f95zone (UnRen-forall embedded) | JAS/RWA/SVAC; needs game `renpy` |
| detect_renpy_version | `tools/detect-renpy-version/` | UnRen-forall embedded | Fallback when `script_version` missing |
| rpatool | `tools/rpatool-py3/` | shiz/rpatool | Standard `.rpa` |
| unrpyc | `tools/unrpyc-py3/` | CensoredUsername + patches | `--try-harder` / deobfuscate |

**Not in UnRen-forall:** rpycCorrector (separate 2020 release). Use `rpyccorrect-py3`, not a forall embed.

**rpmac.sh** (F.Rvv3): reference only at `scripts/reference/rpmac.sh`. Download helper: `scripts/download-sdk.sh`.

**Windows feature reference** (pre-port spec): `_archive/unren-legacy/UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80/`
