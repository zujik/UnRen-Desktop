#!/usr/bin/env bash
# Build slim and full desktop release tarballs for GitHub Releases (Track B).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep '^UNREN_VERSION=' "${ROOT}/unren/config.sh" | head -1 | cut -d'"' -f2)"
OUT="${ROOT}/dist"
STAGING="${OUT}/desktop-staging"
CHECKSUMS="${OUT}/SHA256SUMS-desktop"

INCLUDE=(
    LICENSE NOTICE THIRD_PARTY_LICENSES.md manifest.json
    docs/README-bootstrap.txt
    unren tools patches licenses docs
    scripts/bootstrap.sh scripts/verify_compliance.py
)

INCLUDE_SLIM=( "${INCLUDE[@]}" sdk/stdlib-shims )
INCLUDE_FULL=(
    LICENSE NOTICE THIRD_PARTY_LICENSES.md manifest.json
    UnRen.sh UnRen.command
    unren tools patches licenses docs sdk
    scripts/bootstrap.sh scripts/verify_compliance.py
)

log() { printf '%s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

need_tar() {
    command -v tar >/dev/null 2>&1 || die "tar required"
    tar --help 2>&1 | grep -q -- '-J' || die "tar must support xz (-J)"
}

build_one() {
    local label="$1"
    shift
    local -a paths=("$@")
    local name="unren-desktop-${label}-${VERSION}.tar.xz"
    local work="${STAGING}/${label}"
    local archive="${OUT}/${name}"
    local p rel

    rm -rf "$work"
    mkdir -p "$work"

    for p in "${paths[@]}"; do
        [[ -e "${ROOT}/${p}" ]] || die "missing path for bundle: ${p}"
        if [[ -d "${ROOT}/${p}" ]]; then
            mkdir -p "${work}/$(dirname -- "$p")"
            cp -a "${ROOT}/${p}" "${work}/${p}"
        else
            rel="$(dirname -- "$p")"
            [[ "$rel" == . ]] && rel=""
            [[ -n "$rel" ]] && mkdir -p "${work}/${rel}"
            cp -a "${ROOT}/${p}" "${work}/${p}"
        fi
    done

    mkdir -p "$OUT"
    tar -cJf "$archive" -C "$work" .
    log "Created ${archive} ($(du -h "$archive" | awk '{print $1}'))" >&2
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$OUT" && sha256sum "$name")
    fi
}

main() {
    need_tar
    mkdir -p "$OUT"
    : > "$CHECKSUMS"

    log "Packaging UnRen-Desktop ${VERSION} ..." >&2
    build_one slim "${INCLUDE_SLIM[@]}" >> "$CHECKSUMS"
    build_one full "${INCLUDE_FULL[@]}" >> "$CHECKSUMS"

    log "" >&2
    log "Checksums: ${CHECKSUMS}" >&2
    cat "$CHECKSUMS"
    log "" >&2
    log "Publish to GitHub Releases tag v${VERSION}."
    log "Update manifest.json releases.bundles.*.sha256 from ${CHECKSUMS}."
}

main "$@"
