# Ported tool sources

| Tool | Path | Origin | Notes |
|------|------|--------|-------|
| rpycCorrector | `tools/rpyccorrect-py3/` | AON/SC4X v1.04 (`${UNREN_LOCAL}/_archive/.../rpycCorrector_1.04`) | py3 port; menu **c** / option **9** |
| altrpatool | `tools/altrpatool-py3/` | JoeLurmel @ f95zone (UnRen-forall embedded) | JAS/RWA/SVAC; needs game `renpy` |
| detect_renpy_version | `tools/detect-renpy-version/` | UnRen-forall embedded | Fallback when `script_version` missing |
| forall staging | `tools/forall/` | [UnRen-forall](https://github.com/Lurmel/UnRen-forall) `la_0.77-le_9.7.60-cu_9.7.80` | `detect_rpa_ext`, `detect_archive`, `detect_rpyc_version`, `wos_decrypt_all` — see `ATTRIBUTION.md` |
| rpatool | `tools/rpatool-py3/` | shiz/rpatool | Standard `.rpa` |
| unrpyc | `tools/unrpyc-py3/` | CensoredUsername + patches | `--try-harder` / deobfuscate |

**Not in UnRen-forall:** rpycCorrector (separate 2020 release). Use `rpyccorrect-py3`, not a forall embed.

**rpmac.sh** (F.Rvv3): reference only at `scripts/reference/rpmac.sh`. Download helper: `scripts/download-sdk.sh`.

**Windows feature reference** (pre-port spec): `${UNREN_LOCAL}/_archive/unren-legacy/UnRen-forall-la_0.77-le_9.7.60-cu_9.7.80/`
