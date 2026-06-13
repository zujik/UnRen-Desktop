# Deployment roadmap (future)

**Not implemented.** Current releases are the full `UnRen-Desktop/` folder (flat or `UnRen/` subfolder).

## Milestone order (before public GitHub upload)

1. **Bulk game testing** — `docs/TESTING.md` matrix; log every run in per-game log
2. **Patch** — fix failures found in testing (minimal diffs per game class)
3. **Refactor** — cleanup only after matrix is stable (no behaviour changes mid-test)
4. **Slim deploy** — bootstrap `UnRen.sh` + optional `unren-desktop/` bundle (this doc)
5. **Final upload** — GitHub repo, LFS for `sdk/`, release tarballs, forum post

Do not implement step 4 until steps 1–3 are done.

---

## Target layouts (step 4)

### Online — small drop into game

User copies **one file** into the game root:

```
GameFolder/
├── game/ renpy/ lib/
└── UnRen.sh          ← bootstrap only (~few KB)
```

First run:

1. Bootstrap checks for `unren-desktop/unren/config.sh` (offline bundle present).
2. If missing: download release asset from GitHub (`unren-desktop-VERSION.tar.*`) into `unren-desktop/`.
3. Verify checksum from `manifest.json` (or release `SHA256SUMS`).
4. `source unren-desktop/unren/...` and show the normal menu.

Optional menu entry later: **“Download offline bundle”** — same tarball, for air-gapped reuse.

### Offline — road / no network

User copies **two items**:

```
GameFolder/
├── game/ renpy/
├── UnRen.sh
└── unren-desktop/       ← full tree (unren/, tools/, patches/, sdk/)
    ├── unren/
    ├── tools/
    ├── patches/
    └── sdk/
```

No curl on first run. Same code paths as today’s full-folder tool.

### Maintainer — git clone

Unchanged: clone repo, `git lfs pull`, `./scripts/populate-sdk.sh` if rebuilding slices from `sdk-sources/`.

---

## Bootstrap `UnRen.sh` sketch (pseudocode)

```bash
UNREN_ROOT="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="${UNREN_ROOT}/unren-desktop"
MANIFEST_URL="https://raw.githubusercontent.com/zujik/UnRen-Desktop/main/manifest.json"
RELEASE_BASE="https://github.com/zujik/UnRen-Desktop/releases/download"

if [[ ! -f "${BUNDLE}/unren/config.sh" ]]; then
  # fetch manifest → version + tarball URL + sha256
  # curl -L tarball → tar -xf into unren-desktop/
  # verify sha256
fi

export UNREN_ROOT="${BUNDLE}"
source "${BUNDLE}/unren/config.sh"
# ... same module chain as today ...
unren_main "$@"
```

Repo layout after step 4:

- **`UnRen.sh`** at repo root = bootstrap (also the file users copy)
- **`unren-desktop/`** = payload directory inside release tarball (or git subtree)
- **`sdk/`** may stay in tarball + LFS, or separate “SDK pack” download on first launch (heavier games only)

---

## Release artefacts (step 5)

| Asset | Contents | Audience |
|-------|----------|----------|
| `unren-desktop-full-*.tar.xz` | bootstrap `UnRen.sh` + `unren-desktop/` incl. `sdk/` | Offline / forum zip |
| `unren-desktop-slim-*.tar.xz` | bootstrap + tools/unren/patches; SDK via download | Small download |
| Git clone + LFS | Full dev tree | Contributors |

`personal/sdk-sources/` stays **local maintainer input** — never published (see `sdk/README.md`).

---

## Open decisions (defer until after testing)

- Single tarball vs SDK-on-demand (size vs first-run network)
- Whether bootstrap lives in same repo or `UnRen-Desktop-releases` asset-only repo
- macOS `UnRen.command` wrapper for bootstrap vs double-click `UnRen.sh`
