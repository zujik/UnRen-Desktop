# UnRen-Dependencies mirror setup

UnRen-Desktop and **UnRen-Dependencies** are separate repositories:

| Repository | Role |
|------------|------|
| **UnRen-Dependencies** | Pristine upstream archives and license texts for compliance re-fetch |
| **UnRen-Desktop** | Patched tools, orchestration (`UnRen.sh`, `unren/`), SDK slices, and game workflows |

When you change behaviour, patch **UnRen-Desktop** only. Refresh the mirror when you bump an upstream version or publish a new compliance snapshot.

---

## What goes where

| Component | UnRen-Dependencies (mirror) | UnRen-Desktop (runtime) |
|-----------|----------------------------|-------------------------|
| **unrpyc** | Upstream v2.0.4 (unmodified) | `tools/unrpyc-py3/` + `PATCHES.md` |
| **rpatool** | Upstream shiz/rpatool | `tools/rpatool-py3/` |
| **UnRen-forall** | Lurmel bat bundle + b64-decoded staging scripts | `tools/forall/` + local patches |
| **altrpatool** | Decoded from `UnRen-current.bat` embed | `tools/altrpatool-py3/` py3 port |
| **rpycCorrector** | Original AON/SC4X v1.04 | `tools/rpyccorrect-py3/` py3 port |
| **Licenses** | Same texts as `licenses/` (for re-fetch) | `licenses/` + `verify_compliance.py` |
| **UnRen.sh / sdk / patches** | Never | Always |

---

## Repository layout

Clone both repositories as **siblings** (independent git clones — no submodule required):

```
work/
├── UnRen-Desktop/       # this project
└── UnRen-Dependencies/  # mirror metadata + release assets
```

Each repository has its own remote, branches, and releases.

**Optional local cache** (not published): mirror packaging scripts read upstream trees from a staging directory. Set `MIRROR_STAGING` to any writable path, or let scripts default to a directory resolved via `UNREN_LOCAL` (see `scripts/unren-local.sh`).

---

## Initial mirror repository

Create the GitHub repository and push the scaffold:

```bash
git clone https://github.com/zujik/UnRen-Dependencies.git
cd UnRen-Dependencies
# README.md, LICENSE, NOTICE, manifest.json, docs/SOURCE_MAP.md
git init -b main   # if starting from a fresh folder
git add README.md LICENSE NOTICE manifest.json docs/
git commit -m "Initial vendor mirror scaffold for UnRen-Desktop compliance"
gh repo create zujik/UnRen-Dependencies --public --source=. --remote=origin \
  --description "Vendor mirror for UnRen-Desktop compliance (per-upstream licenses)"
git push -u origin main
```

Public mirror is fine for GPL/MIT/BSD redistribution when license files are preserved.

**GitHub repo license:** choose **GNU GPLv3** for the repository curation work. Component archives retain their upstream licenses.

---

## Stage pristine upstream (one-time per version)

From your **UnRen-Desktop** clone, download upstream into a staging directory:

```bash
cd /path/to/UnRen-Desktop
STAGING="${MIRROR_STAGING:-/tmp/unren-mirror-staging}"
mkdir -p "${STAGING}"

# unrpyc 2.0.4
git clone --depth 1 --branch v2.0.4 \
  https://github.com/CensoredUsername/unrpyc.git "${STAGING}/unrpyc-2.0.4"

# rpatool — canonical upstream (not the older embed inside the .bat)
git clone --depth 1 https://codeberg.org/shiz/rpatool.git "${STAGING}/rpatool"

# UnRen-forall — clone repo (provenance + bat files on main)
git clone --depth 1 https://github.com/Lurmel/UnRen-forall.git "${STAGING}/unren-forall-repo"

# Copy release bat files from the clone (same content as the GitHub release zip)
mkdir -p "${STAGING}/unren-forall-la_0.77"
cp -a "${STAGING}/unren-forall-repo/UnRen-forall.bat" \
      "${STAGING}/unren-forall-repo/UnRen-current.bat" \
      "${STAGING}/unren-forall-repo/UnRen-legacy.bat" \
      "${STAGING}/unren-forall-repo/UnRen-cfg.txt" \
      "${STAGING}/unren-forall-repo/UnRen-link.txt" \
      "${STAGING}/unren-forall-la_0.77/"

# Alternative: download the exact release zip from Lurmel/UnRen-forall Releases
# and unzip into ${STAGING}/

# Decode embedded Python from UnRen-current.bat (upstream copy, not tools/forall/)
chmod +x scripts/extract-unren-forall-b64.py
python3 scripts/extract-unren-forall-b64.py \
  "${STAGING}/unren-forall-la_0.77/UnRen-current.bat" \
  "${STAGING}/unren-forall-scripts"

mkdir -p "${STAGING}/altrpatool-upstream"
cp "${STAGING}/unren-forall-scripts/altrpatool.py" "${STAGING}/altrpatool-upstream/"

# rpycCorrector — obtain from the F95 forum release (not in the Lurmel repo)
# Place under: ${STAGING}/rpyc-corrector-1.04/
```

If the original rpycCorrector archive is unavailable, note that in `docs/SOURCE_INVENTORY.md`. The **license file** in `licenses/` remains valid for compliance re-fetch.

---

## Build release assets

```bash
cd /path/to/UnRen-Desktop
MIRROR_STAGING=/path/to/staging ./scripts/package-mirror-release.sh
```

Output: `dist/mirror-v1.0.0/` containing:

- `*.txt` license files (flat names — copied from UnRen-Desktop `licenses/`)
- `*.tar.xz` per component (from the staging directory when present)

**Important:** GitHub Releases store assets by **basename only** (no `licenses/` folder in download URLs). `manifest.json` → `license_download_url` must match, e.g. `.../v1.0.0/unrpyc.MIT.txt` not `.../licenses/unrpyc.MIT.txt`.

Review the script summary for any `SKIP` lines before publishing.

---

## Publish a GitHub Release

```bash
cd /path/to/UnRen-Desktop
gh release create v1.0.0 \
  dist/mirror-v1.0.0/unrpyc-2.0.4.tar.xz \
  dist/mirror-v1.0.0/rpatool.tar.xz \
  dist/mirror-v1.0.0/unren-forall-la_0.77.tar.xz \
  dist/mirror-v1.0.0/altrpatool.tar.xz \
  dist/mirror-v1.0.0/rpyc-corrector-1.04.tar.xz \
  dist/mirror-v1.0.0/*.txt \
  --repo zujik/UnRen-Dependencies \
  --title "v1.0.0 — initial compliance mirror" \
  --notes "Pristine upstream snapshots + license texts for UnRen-Desktop manifest.json"
```

Or upload via GitHub web UI: Release → attach all files from `dist/mirror-v1.0.0/`.

URLs must match `manifest.json` in UnRen-Desktop.

---

## Verify

```bash
cd /path/to/UnRen-Desktop
python3 scripts/verify_compliance.py .
```

All checks should pass. Add a row to `docs/SOURCE_INVENTORY.md` audit log with the release date.

---

## Ongoing maintenance

| Action | Repository |
|--------|------------|
| Fix decompile / menu / SDK | UnRen-Desktop |
| Patch unrpyc / forall | UnRen-Desktop |
| Release full tool zip | UnRen-Desktop Releases |
| Upstream version bump snapshot | UnRen-Dependencies |
| License text correction | Both (Desktop first, then re-package mirror) |

When a dependency version changes:

1. Refresh the staging directory with the new upstream tree.
2. Run `scripts/package-mirror-release.sh`.
3. Publish a new tag on **UnRen-Dependencies**.
4. Update `manifest.json` URLs in **UnRen-Desktop**.

---

## Related

- `docs/SOURCE_INVENTORY.md` — provenance audit trail
- `manifest.json` — `dependencies.*.download_url`
- `scripts/package-mirror-release.sh` — build release folder
- `UnRen-Dependencies/docs/SOURCE_MAP.md` — per-asset upstream map
