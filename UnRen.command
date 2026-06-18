#!/usr/bin/env bash
# macOS entry — pass game path as arguments (use Terminal; Finder drop is unreliable).
# Downloads UnRen.sh on first run if only this file was copied from the release.
set -euo pipefail

UNREN_RELEASE_REPO="${UNREN_RELEASE_REPO:-https://github.com/zujik/UnRen-Desktop}"
UNREN_RELEASE_TAG="${UNREN_RELEASE_TAG:-v2.0.0-alpha.1}"

cd "$(dirname "$0")" || exit 1

# Gatekeeper quarantine on downloaded scripts (dikau-style).
xattr -cr . 2>/dev/null || true

_unren_fetch_unren_sh() {
    local url tmp
    [[ -f ./UnRen.sh ]] && return 0
    url="${UNREN_RELEASE_REPO}/releases/download/${UNREN_RELEASE_TAG}/UnRen.sh"
    echo "  Fetching UnRen.sh ..." >&2
    echo "  URL: ${url}" >&2
    tmp="./UnRen.sh.part"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$tmp" "$url"
    else
        echo "[!] Need curl or wget to fetch UnRen.sh" >&2
        exit 1
    fi
    mv -f "$tmp" ./UnRen.sh
    chmod +x ./UnRen.sh
}

_unren_fetch_unren_sh
chmod +x ./UnRen.sh 2>/dev/null || true
exec ./UnRen.sh "$@"
