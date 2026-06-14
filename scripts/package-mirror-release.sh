#!/usr/bin/env bash
# Build UnRen-Dependencies release assets from pristine .mirror-staging/ trees.
# Patched UnRen-Desktop tools/ are NOT packaged — see docs/MIRROR_SETUP.md.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="${MIRROR_STAGING:-${ROOT}/.mirror-staging}"
VERSION="${MIRROR_VERSION:-v1.0.0}"
OUT="${MIRROR_OUT:-${ROOT}/dist/mirror-${VERSION}}"

log() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
skip() { warn "SKIP $1 — $2"; }

package_dir() {
    local name="$1"
    local src="$2"
    local archive="$3"
    if [[ ! -d "$src" ]]; then
        skip "$archive" "missing staging dir: $src"
        return 1
    fi
    mkdir -p "$(dirname "${OUT}/${archive}")"
    tar -cJf "${OUT}/${archive}" -C "$(dirname "$src")" "$(basename "$src")"
    log "OK  ${archive}  ←  ${src}"
}

mkdir -p "${OUT}"

# License texts — flat filenames (GitHub Releases use basename only, no licenses/ prefix)
for f in unrpyc.MIT.txt unren_forall.GPL-3.txt rpyc_corrector.BSD-2-Clause.txt \
         altrpatool.GPL-3.txt rpatool.WTFPL.txt GPL-3.0.txt; do
    src="${ROOT}/licenses/${f}"
    if [[ -f "$src" ]]; then
        cp "$src" "${OUT}/${f}"
        log "OK  ${f}"
    else
        warn "missing ${src}"
    fi
done

# Pristine upstream tool trees (maintainer populates .mirror-staging — see MIRROR_SETUP.md)
package_dir unrpyc "${STAGING}/unrpyc-2.0.4" "unrpyc-2.0.4.tar.xz" || true
package_dir rpatool "${STAGING}/rpatool" "rpatool.tar.xz" || true
package_dir forall "${STAGING}/unren-forall-scripts" "unren-forall-la_0.77.tar.xz" || true
package_dir rpyc "${STAGING}/rpyc-corrector-1.04" "rpyc-corrector-1.04.tar.xz" || true
package_dir altra "${STAGING}/altrpatool-upstream" "altrpatool.tar.xz" || true

log ""
log "Mirror release folder: ${OUT}"
log "Upload contents to: https://github.com/zujik/UnRen-Dependencies/releases/download/${VERSION}/"
log ""
log "Next: gh release create ${VERSION} ${OUT}/* --repo zujik/UnRen-Dependencies"
