#!/usr/bin/env bash
# Download a full Ren'Py SDK from renpy.org into sdk-sources/ for populate-sdk.sh.
#
# Version detection borrows from rpmac.sh by F.Rvv3 (f95zone thread 287097, pastebin).
# UnRen-Desktop does not repackage games onto macOS — only fetches SDK trees for trimming.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERSONAL="$(cd "${ROOT}/.." && pwd)"
SDK_SOURCES="${RENPY_SDK_SOURCES:-${PERSONAL}/sdk-sources}"
VERSION=""
DOWNLOAD_ONLY=false

die() { echo "download-sdk: $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [-d] [VERSION]

Download renpy-VERSION-sdk.tar.bz2 from renpy.org into:
  ${SDK_SOURCES}/renpy-VERSION-sdk/

Options:
  -d    Download only (no populate-sdk run)
  -h    Help

If VERSION is omitted, detect from a game directory (RENPY_GAME or cwd).

Inspired by rpmac.sh — author F.Rvv3
  https://f95zone.to/threads/rpmac-automatic-renpy-game-converter-for-mac.287097/
EOF
}

detect_version_from_game() {
    local app="$1" sv
    [[ -d "${app}/game" ]] || die "Not a game directory: ${app}"

    if [[ -f "${app}/renpy/vc_version.py" ]]; then
        sv="$(perl -nle 'if (/\b(?:vc_)?version\s*=\s*[\x22\x27]?([\d.a-zA-Z]+)/) {
            my $v = $1; $v =~ s/\.\d{4,}$//; print $v if $v =~ /\./ }' \
            "${app}/renpy/vc_version.py" 2>/dev/null | head -1)"
        [[ -n "$sv" ]] && { echo "$sv"; return 0; }
    fi

    if [[ -f "${app}/renpy/__init__.py" ]]; then
        sv="$(perl -nle 'if (/version_tuple\s*=\s*\((.*?)\)/) {
            my @nums = $1 =~ /(\d+)/g; print join(".", @nums) }' \
            "${app}/renpy/__init__.py" 2>/dev/null | head -1)"
        [[ -n "$sv" ]] && { echo "$sv"; return 0; }
    fi

    if [[ -f "${ROOT}/tools/detect-renpy-version/detect_renpy_version.py" ]]; then
        sv="$(env -u PYTHONHOME -u PYTHONPATH python3 \
            "${ROOT}/tools/detect-renpy-version/detect_renpy_version.py" "${app}" 2>/dev/null || true)"
        [[ -n "$sv" ]] && { echo "$sv"; return 0; }
    fi

    die "Could not detect Ren'Py version in ${app}"
}

download_sdk() {
    local ver="$1"
    local url="https://www.renpy.org/dl/${ver}/renpy-${ver}-sdk.tar.bz2"
    local tmp="/tmp/renpy-${ver}-sdk.tar.bz2"
    local dest="${SDK_SOURCES}/renpy-${ver}-sdk"

    mkdir -p "${SDK_SOURCES}"
    if [[ -d "$dest" ]]; then
        echo "Already present: ${dest}"
        return 0
    fi

    echo "Downloading ${url}"
    curl -Lf -o "$tmp" "$url" || die "curl failed for ${url}"
    echo "Extracting to ${SDK_SOURCES}"
    tar -xjf "$tmp" -C "${SDK_SOURCES}"
    rm -f "$tmp"
    echo "Done: ${dest}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d) DOWNLOAD_ONLY=true; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) die "Unknown option: $1" ;;
        *) VERSION="$1"; shift ;;
    esac
done

if [[ -z "$VERSION" ]]; then
    GAME="${RENPY_GAME:-${PWD}}"
    VERSION="$(detect_version_from_game "$GAME")"
    echo "Detected SDK version: ${VERSION}"
fi

download_sdk "$VERSION"

if [[ "$DOWNLOAD_ONLY" == false ]]; then
    echo "Run scripts/populate-sdk.sh to copy trimmed slices into sdk/ (if this version is configured)."
fi
