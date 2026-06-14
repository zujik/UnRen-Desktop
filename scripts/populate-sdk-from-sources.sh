#!/usr/bin/env bash
# Populate sdk/py3-8.5.3 and sdk/py2-7.8.7 from full SDK trees under RENPY_SDK_SOURCES.
# Safe to re-run: uses .linux-full extract; populate skips if dest already OK
# unless FORCE_POPULATE_SDK=1.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=unren-local.sh
source "$(dirname "$0")/unren-local.sh"
UNREN_LOCAL="$(unren_local_dir "${ROOT}")"
SRC="${RENPY_SDK_SOURCES:-${UNREN_LOCAL}/sdk-sources}"
STAGE="${SRC}/.linux-full"

die() { echo "populate-sdk-from-sources: $*" >&2; exit 1; }

extract_if_needed() {
    local ver="$1"
    local tbz="${SRC}/renpy-${ver}-sdk.tar.bz2"
    local dest="${STAGE}/renpy-${ver}-sdk"
    local py_tag plat pybin

    case "$ver" in
        8.5.3) py_tag=py3; plat=linux-x86_64; pybin="${dest}/lib/py3-${plat}/python" ;;
        7.8.7) py_tag=py2; plat=linux-x86_64; pybin="${dest}/lib/py2-${plat}/python" ;;
        *) die "unsupported version: $ver" ;;
    esac

    [[ -f "$tbz" ]] || die "missing tarball: $tbz"
    mkdir -p "$STAGE"

    if [[ -x "$pybin" ]]; then
        echo "  already extracted: $dest"
        return 0
    fi

    echo "  extracting ${tbz} -> ${STAGE}"
    tar -xjf "$tbz" -C "$STAGE"
    [[ -x "$pybin" ]] || die "no Linux python in ${dest}"
}

echo "UnRen-Desktop: populate from ${SRC}"
extract_if_needed "8.5.3"
extract_if_needed "7.8.7"

RENPY_PY3_SRC="${STAGE}/renpy-8.5.3-sdk" \
RENPY_PY2_SRC="${STAGE}/renpy-7.8.7-sdk" \
FORCE_POPULATE_SDK="${FORCE_POPULATE_SDK:-1}" \
POPULATE_DEST_ROOT="${POPULATE_DEST_ROOT:-${ROOT}}" \
"${ROOT}/scripts/populate-sdk.sh"

dest="${POPULATE_DEST_ROOT:-${ROOT}}"

echo
echo "Verify:"
if [[ -x "${dest}/sdk/py3-8.5.3/lib/py3-linux-x86_64/python" ]]; then
    echo "  OK  ${dest}/sdk/py3-8.5.3/lib/py3-linux-x86_64/python"
else
    echo "  FAIL ${dest}/sdk/py3-8.5.3/lib/py3-linux-x86_64/python"
    exit 1
fi
if [[ -x "${dest}/sdk/py2-7.8.7/lib/py2-linux-x86_64/python" ]]; then
    echo "  OK  ${dest}/sdk/py2-7.8.7/lib/py2-linux-x86_64/python"
else
    echo "  (py2-7.8.7 optional — not populated)"
fi
echo "Done."
