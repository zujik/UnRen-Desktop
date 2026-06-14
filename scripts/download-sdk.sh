#!/usr/bin/env bash
# Download a full Ren'Py SDK from renpy.org into RENPY_SDK_SOURCES for populate-sdk.sh.
#
# Version detection borrows from rpmac.sh by F.Rvv3 (f95zone thread 287097, pastebin).
# UnRen-Desktop does not repackage games onto macOS — only fetches SDK trees for trimming.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=unren-local.sh
source "$(dirname "$0")/unren-local.sh"
UNREN_LOCAL="$(unren_local_dir "${ROOT}")"
SDK_SOURCES="${RENPY_SDK_SOURCES:-${UNREN_LOCAL}/sdk-sources}"
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

sdk_download_complete() {
    local ver="$1" dest="$2"
    local py_tag plat stdlib

    case "$(uname -s)" in
        Darwin)
            if [[ -d "${dest}/lib/py3-darwin-arm64" ]]; then
                plat="darwin-arm64"
            else
                plat="darwin-x86_64"
            fi
            ;;
        Linux)
            case "$(uname -m)" in
                i686|i386) plat="linux-i686" ;;
                *) plat="linux-x86_64" ;;
            esac
            ;;
        *) return 0 ;;  # Windows or unknown: any tree is fine
    esac

    case "$ver" in
        8.*|9.*|10.*)
            py_tag="py3"
            [[ -x "${dest}/lib/${py_tag}-${plat}/python" || -x "${dest}/lib/${py_tag}-${plat}/python.real" ]]
            ;;
        *)
            py_tag="py2"
            stdlib="${dest}/lib/python2.7/site.py"
            [[ -f "$stdlib" && -x "${dest}/lib/${py_tag}-${plat}/python" ]]
            ;;
    esac
}

download_sdk() {
    local ver="$1"
    local url="https://www.renpy.org/dl/${ver}/renpy-${ver}-sdk.tar.bz2"
    local tmp="/tmp/renpy-${ver}-sdk.tar.bz2"
    local dest="${SDK_SOURCES}/renpy-${ver}-sdk"

    mkdir -p "${SDK_SOURCES}"
    if [[ -d "$dest" ]]; then
        if sdk_download_complete "$ver" "$dest"; then
            echo "Already present (Linux/macOS runtime OK): ${dest}"
            return 0
        fi
        if [[ "${FORCE_SDK_DOWNLOAD:-}" != 1 ]]; then
            echo "Incomplete SDK at ${dest} (Windows-only or missing lib/)."
            echo "  Not deleting. Re-download with: FORCE_SDK_DOWNLOAD=1 $0 ${ver}"
            return 1
        fi
        echo "Incomplete SDK (Windows-only or missing lib/): ${dest}"
        echo "  FORCE_SDK_DOWNLOAD=1 — replacing from renpy.org ..."
        rm -rf "$dest"
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
