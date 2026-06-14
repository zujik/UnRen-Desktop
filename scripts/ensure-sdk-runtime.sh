#!/usr/bin/env bash
# Fetch Ren'Py SDK runtimes only when sdk/ truly lacks Linux/macOS libs.
# Does NOT delete or overwrite an existing working sdk/ slice.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-${UNREN_APP:-}}"
CACHE="${RENPY_SDK_CACHE:-${ROOT}/.sdk-sources-cache}"
PLATFORM="${RENPY_PLATFORM:-linux-x86_64}"
PY3_DEST="${ROOT}/sdk/py3-8.5.3"

die() { echo "ensure-sdk-runtime: $*" >&2; exit 1; }

platform_py3_name() {
    case "$PLATFORM" in
        mac-universal|darwin-*|Darwin-*)
            if [[ -d "${1}/lib/py3-darwin-arm64" ]]; then
                echo "darwin-arm64"
            else
                echo "darwin-x86_64"
            fi
            ;;
        linux-i686|*-i686|*-i386) echo "linux-i686" ;;
        *) echo "linux-x86_64" ;;
    esac
}

sdk_dest_has_linux_py3() {
    local dest="$1" plat
    plat="$(platform_py3_name "$dest")"
    [[ -x "${dest}/lib/py3-${plat}/python" || -x "${dest}/lib/py3-${plat}/python.real" ]]
}

sdk_src_has_linux_py3() {
    local src="$1" plat
    plat="$(platform_py3_name "$src")"
    [[ -x "${src}/lib/py3-${plat}/python" || -x "${src}/lib/py3-${plat}/python.real" ]]
}

fetch_full_sdk() {
    local ver="$1"
    local dest="${CACHE}/renpy-${ver}-sdk"
    local url="https://www.renpy.org/dl/${ver}/renpy-${ver}-sdk.tar.bz2"
    local tmp staging

    mkdir -p "$CACHE"
    if [[ -d "$dest" ]] && sdk_src_has_linux_py3 "$dest"; then
        echo "ensure-sdk-runtime: cache already has Linux runtime: ${dest}"
        return 0
    fi

    staging="${CACHE}/.staging-renpy-${ver}-sdk"
    rm -rf "$staging"
    mkdir -p "$staging"

    echo "ensure-sdk-runtime: downloading Ren'Py ${ver} SDK ..."
    tmp="$(mktemp "/tmp/renpy-${ver}-sdk.XXXXXX.tar.bz2")"
    curl -Lf --progress-bar -o "$tmp" "$url" || die "download failed: ${url}"
    echo "ensure-sdk-runtime: extracting ..."
    tar -xjf "$tmp" -C "$staging"
    rm -f "$tmp"

    [[ -d "${staging}/renpy-${ver}-sdk" ]] || die "extract missing: ${staging}/renpy-${ver}-sdk"
    sdk_src_has_linux_py3 "${staging}/renpy-${ver}-sdk" || die "downloaded SDK has no Linux python under lib/py3-*"

    if [[ -d "$dest" ]]; then
        echo "ensure-sdk-runtime: merging into cache (not deleting ${dest})"
        cp -a "${staging}/renpy-${ver}-sdk"/. "$dest/"
    else
        mv "${staging}/renpy-${ver}-sdk" "$dest"
    fi
    rm -rf "$staging"
}

main() {
    if sdk_dest_has_linux_py3 "$PY3_DEST"; then
        echo "ensure-sdk-runtime: sdk/py3-8.5.3 already has Linux runtime — nothing to do."
        return 0
    fi

    echo "ensure-sdk-runtime: sdk/ needs Linux libs (will not overwrite existing binaries)"
    echo "  cache: ${CACHE}"
    echo

    fetch_full_sdk "8.5.3"
    RENPY_PY3_SRC="${CACHE}/renpy-8.5.3-sdk" \
        RENPY_PY2_SRC="${CACHE}/renpy-7.8.7-sdk" \
        "${ROOT}/scripts/populate-sdk.sh" --py3-only

    if sdk_dest_has_linux_py3 "$PY3_DEST"; then
        echo
        echo "ensure-sdk-runtime: done."
        return 0
    fi
    die "populate finished but sdk/py3-8.5.3 still has no lib/py3-linux-x86_64/python"
}

main "$@"
