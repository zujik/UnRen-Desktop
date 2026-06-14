# Deployment and license compliance

**Current workflow:** copy the full `UnRen-Desktop/` tree into the game folder,
then run `./UnRen.sh`. A single-script bootstrap download is described below as a
future packaging option.

**Maintainer:** Kijuz (F95zone) · GitHub: [zujik](https://github.com/zujik)

---

## License posture (summary)

| Question | Answer |
|----------|--------|
| Is UnRen-Desktop itself covered? | **Yes** — GPL-3.0-only, `LICENSE` + `NOTICE` |
| Must the whole project be GPL? | **Yes** for offline bundles — UnRen-forall and altrpatool are GPL-3.0 |
| Bootstrap-only `UnRen.sh`? | Still GPL-3.0 orchestrator; deps fetched at runtime keep own licenses |
| Ren'Py SDK in `sdk/`? | **Yes** — ship `sdk/*/LICENSE.txt` with any binary SDK pack |
| rpycCorrector? | **BSD-2-Clause** — header in source + `licenses/rpyc_corrector.BSD-2-Clause.txt` |
| Game assets? | **Not included** — user’s own installs; disclaimer in `THIRD_PARTY_LICENSES.md` |

Full detail: `THIRD_PARTY_LICENSES.md`, `manifest.json`, `docs/SOURCE_INVENTORY.md`.

---

## What every redistribution must include

Whether you ship **git clone**, **full tarball**, or **bootstrap download**, the
user must end up with:

| File / path | Required when |
|-------------|---------------|
| `LICENSE` | Always |
| `NOTICE` | Always |
| `THIRD_PARTY_LICENSES.md` | Always |
| `tools/altrpatool-py3/COPYING` | Whenever `tools/altrpatool-py3/` is present |
| `sdk/*/LICENSE.txt` | Whenever `sdk/` binaries are present |
| `tools/*/README.md` | Recommended (per-tool attribution) |

**Release checklist** (maintainer, before uploading to GitHub Releases):

```bash
# Verify license files exist in tree
test -f LICENSE NOTICE THIRD_PARTY_LICENSES.md
test -f tools/altrpatool-py3/COPYING
for slice in py3-8.5.3 py2-7.8.7 py2-6.99.14.3 py2-5.6.7; do
  test -f "sdk/${slice}/LICENSE.txt" || echo "MISSING sdk/${slice}/LICENSE.txt"
done
```

---

## Download-on-first-run: compliance rules

When bootstrap `UnRen.sh` downloads payloads (future), **each download must
preserve license files**. Never fetch “code only” without legal notices.

### Bundle types

| Download | Contents | License files to verify after extract |
|----------|----------|--------------------------------------|
| **Full bundle** (`unren-desktop-full-*.tar.*`) | `unren/`, `tools/`, `patches/`, `sdk/` | All rows in table above |
| **Slim bundle** (`unren-desktop-slim-*.tar.*`) | `unren/`, `tools/`, `patches/` (no `sdk/`) | LICENSE, NOTICE, THIRD_PARTY, COPYING |
| **SDK pack** (`unren-sdk-<slice>-*.tar.*`) | `sdk/<slice>/` only | `sdk/<slice>/LICENSE.txt` |
| **Ren'Py SDK fetch** (`ensure-sdk-runtime.sh`) | Merges from renpy.org tarball | Copy `LICENSE.txt` into slice after populate |

### Bootstrap pseudocode (with compliance)

```bash
UNREN_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="${UNREN_ROOT}/unren-desktop"

download_and_verify() {
  local url="$1" sha256="$2" dest="$3"
  # curl -L "$url" → tar -xf into "$dest"
  # verify sha256
  _unren_verify_license_files "$dest"
}

_unren_verify_license_files() {
  local root="$1"
  local missing=0
  for f in LICENSE NOTICE THIRD_PARTY_LICENSES.md; do
    [[ -f "${root}/${f}" ]] || { echo "missing ${f}"; missing=1; }
  done
  [[ -f "${root}/tools/altrpatool-py3/COPYING" ]] || { echo "missing altrpatool COPYING"; missing=1; }
  if [[ -d "${root}/sdk" ]]; then
    for slice in "${root}"/sdk/*/; do
      [[ -f "${slice}/LICENSE.txt" ]] || { echo "missing ${slice}/LICENSE.txt"; missing=1; }
    done
  fi
  (( missing )) && { echo "Download incomplete — license files missing. Refusing to run."; exit 1; }
}

if [[ ! -f "${BUNDLE}/unren/config.sh" ]]; then
  download_and_verify "$RELEASE_URL" "$RELEASE_SHA256" "$BUNDLE"
fi

export UNREN_ROOT="${BUNDLE}"
# source module chain …
```

### `manifest.json` compliance fields

Implemented in `manifest.json`:

```json
"compliance_block": {
  "project_license": "GPL-3.0-only",
  "required_files": ["LICENSE", "NOTICE", "THIRD_PARTY_LICENSES.md", "docs/SOURCE_INVENTORY.md"],
  "mirror_repository": "https://github.com/zujik/UnRen-Dependencies"
},
"dependencies": {
  "unrpyc": { "expected_license_file": "licenses/unrpyc.MIT.txt", ... },
  "unren_forall": { ... },
  "rpyc_corrector": { ... }
}
```

Startup audit: `scripts/verify_compliance.py` (invoked from `unren/compliance.sh`).
Set `UNREN_STRICT_COMPLIANCE=1` to refuse running on audit failure.

---

## Target layouts

### A — Today (full copy)

```
GameFolder/
├── game/ renpy/ lib/
├── UnRen.sh
├── unren/ tools/ patches/ sdk/
```

No download. All license files already on disk.

### B — Future online (bootstrap)

```
GameFolder/
├── game/ renpy/ lib/
└── UnRen.sh                    ← small bootstrap only
```

First run downloads `unren-desktop/` (or extracts from cached tarball next to
`UnRen.sh`). Bootstrap **must** run `_unren_verify_compliance` before menu.

### C — Future offline (two-item copy)

```
GameFolder/
├── UnRen.sh
└── unren-desktop/              ← full payload, same as today’s tree
```

No network. Same compliance files as layout A.

### D — Maintainer git clone

```bash
git clone https://github.com/zujik/UnRen-Desktop.git
cd UnRen-Desktop
git lfs pull
./UnRen.sh /path/to/GameFolder
```

Optional: `./scripts/populate-sdk.sh` / `ensure-sdk-runtime.sh` — after fetch,
confirm `LICENSE.txt` landed in each `sdk/<slice>/`.

---

## Release artefacts

| Asset | Audience | SDK included | Size tradeoff |
|-------|----------|--------------|---------------|
| `unren-desktop-full-*.tar.xz` | Forum / offline | Yes (LFS binaries) | Large |
| `unren-desktop-slim-*.tar.xz` | Quick download | No — SDK on demand | Small first fetch |
| `unren-sdk-<slice>-*.tar.bz2` | SDK-only refresh | One slice | Medium |
| Git + LFS | Developers | Full tree | Clone + `git lfs pull` |

`.sdk-sources-cache/` and mirror staging directories (see `MIRROR_STAGING` in
`scripts/package-mirror-release.sh`) are **local build caches** — never publish
(see `.gitignore`).

---

## Future packaging work

- Bootstrap `UnRen.sh` with download, sha256 verification, and license checks
- Full vs slim release tarballs (with and without `sdk/`)
- Optional `unren-desktop/` subfolder layout for game installs

See `docs/MIRROR_SETUP.md` for the compliance mirror; `docs/TESTING.md` for the
game compatibility matrix.

---

## Related docs

- `docs/TESTING.md` — game matrix and regression anchors
- `docs/SOURCE_INVENTORY.md` — download provenance and mirror audit log
- `docs/MIRROR_SETUP.md` — two-repo mirror setup (UnRen-Dependencies)
- `THIRD_PARTY_LICENSES.md` — component licenses
- `tools/SOURCES.md` — tool paths and upstream URLs
- `sdk/README.md` — SDK slice layout and LFS
