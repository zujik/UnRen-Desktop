#!/usr/bin/env bash
# Copy trimmed Ren'Py SDK runtime slices into sdk/py3-8.5.3 and sdk/py2-7.8.7.
# Requires full SDK trees (from renpy.org) on disk — does not download by default.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERSONAL="$(cd "${ROOT}/.." && pwd)"
SDK_SOURCES="${RENPY_SDK_SOURCES:-${PERSONAL}/sdk-sources}"
PY3_SRC="${RENPY_PY3_SRC:-${SDK_SOURCES}/renpy-8.5.3-sdk}"
PY2_SRC="${RENPY_PY2_SRC:-${SDK_SOURCES}/renpy-7.8.7-sdk}"
PY3_DEST="${ROOT}/sdk/py3-8.5.3"
PY2_DEST="${ROOT}/sdk/py2-7.8.7"

die() { echo "populate-sdk: $*" >&2; exit 1; }

copy_py3() {
    [[ -d "$PY3_SRC" ]] || die "Python 3 SDK not found: $PY3_SRC"
    mkdir -p "${PY3_DEST}/lib"
    for item in renpy.sh renpy.py LICENSE.txt; do
        [[ -f "${PY3_SRC}/${item}" ]] && cp -a "${PY3_SRC}/${item}" "${PY3_DEST}/"
    done
    rm -rf "${PY3_DEST}/renpy"
    cp -a "${PY3_SRC}/renpy" "${PY3_DEST}/renpy"
    for libpart in python3.12 py3-linux-x86_64 py3-linux-i686 py3-darwin-x86_64 py3-darwin-arm64; do
        if [[ -d "${PY3_SRC}/lib/${libpart}" ]]; then
            rm -rf "${PY3_DEST}/lib/${libpart}"
            cp -a "${PY3_SRC}/lib/${libpart}" "${PY3_DEST}/lib/${libpart}"
            echo "  + lib/${libpart}"
        fi
    done
    chmod +x "${PY3_DEST}/renpy.sh" 2>/dev/null || true
    find "${PY3_DEST}/lib" -name python -type f -exec chmod +x {} + 2>/dev/null || true
}

copy_py2() {
    [[ -d "$PY2_SRC" ]] || die "Python 2 SDK not found: $PY2_SRC"
    mkdir -p "${PY2_DEST}/lib"
    for item in renpy.sh renpy.py LICENSE.txt; do
        [[ -f "${PY2_SRC}/${item}" ]] && cp -a "${PY2_SRC}/${item}" "${PY2_DEST}/"
    done
    rm -rf "${PY2_DEST}/renpy"
    cp -a "${PY2_SRC}/renpy" "${PY2_DEST}/renpy"
    for libpart in python2.7 py2-linux-x86_64 py2-linux-i686 py2-darwin-x86_64; do
        if [[ -d "${PY2_SRC}/lib/${libpart}" ]]; then
            rm -rf "${PY2_DEST}/lib/${libpart}"
            cp -a "${PY2_SRC}/lib/${libpart}" "${PY2_DEST}/lib/${libpart}"
            echo "  + lib/${libpart}"
        fi
    done
    chmod +x "${PY2_DEST}/renpy.sh" 2>/dev/null || true
    find "${PY2_DEST}/lib" -name python -type f -exec chmod +x {} + 2>/dev/null || true
}

echo "UnRen-Desktop: populating SDK runtimes"
echo "  py3 source: ${PY3_SRC} -> ${PY3_DEST}"
copy_py3
echo "  py2 source: ${PY2_SRC} -> ${PY2_DEST}"
copy_py2
echo "Done."
