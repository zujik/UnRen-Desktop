#!/usr/bin/env bash
# Package single-file Linux starter (UnRen.sh) and macOS UnRen.command.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep '^UNREN_VERSION=' "${ROOT}/unren/config.sh" | head -1 | cut -d'"' -f2)"
OUT="${ROOT}/dist"
STAGING="${OUT}/starter-staging"
LINUX_ARCHIVE="${OUT}/unren-desktop-starter-${VERSION}.tar.xz"
MAC_ARCHIVE="${OUT}/unren-desktop-starter-mac-${VERSION}.tar.xz"
CHECKSUMS="${OUT}/SHA256SUMS-starter"

log() { printf '%s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

need_tar() {
    command -v tar >/dev/null 2>&1 || die "tar required"
    tar --help 2>&1 | grep -q -- '-J' || die "tar must support xz (-J)"
}

main() {
    need_tar
    "${ROOT}/scripts/sync-bootstrap-into-unren.sh"
    mkdir -p "$OUT" "${STAGING}/linux" "${STAGING}/mac"

    cp -a "${ROOT}/UnRen.sh" "${STAGING}/linux/UnRen.sh"
    chmod +x "${STAGING}/linux/UnRen.sh"
    tar -cJf "$LINUX_ARCHIVE" -C "${STAGING}/linux" UnRen.sh
    log "Created ${LINUX_ARCHIVE} ($(du -h "$LINUX_ARCHIVE" | awk '{print $1}'))" >&2

    cp -a "${ROOT}/UnRen.command" "${STAGING}/mac/UnRen.command"
    chmod +x "${STAGING}/mac/UnRen.command"
    tar -cJf "$MAC_ARCHIVE" -C "${STAGING}/mac" UnRen.command
    log "Created ${MAC_ARCHIVE} ($(du -h "$MAC_ARCHIVE" | awk '{print $1}'))" >&2

    cp -a "${ROOT}/UnRen.sh" "${OUT}/UnRen.sh"
    chmod +x "${OUT}/UnRen.sh"
    log "Created ${OUT}/UnRen.sh (release asset for UnRen.command fetch)" >&2

    : > "$CHECKSUMS"
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$OUT" && sha256sum "$(basename "$LINUX_ARCHIVE")") | tee -a "$CHECKSUMS"
        (cd "$OUT" && sha256sum "$(basename "$MAC_ARCHIVE")") | tee -a "$CHECKSUMS"
        (cd "$OUT" && sha256sum "UnRen.sh") | tee -a "$CHECKSUMS"
    fi

    log "" >&2
    log "Linux:  place UnRen.sh in game folder, run ./UnRen.sh" >&2
    log "macOS:  save UnRen.command in ~/UnRen-Desktop, drag game onto it" >&2
    log "Publish UnRen.sh, both starter tarballs, and update manifest.json" >&2
}

main "$@"
