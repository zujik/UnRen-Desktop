#!/usr/bin/env bash
# Copy trimmed Ren'Py SDK runtime slices into sdk/py3-8.5.3 and sdk/py2-7.8.7.
# Never overwrites a working Linux/macOS runtime unless FORCE_POPULATE_SDK=1.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERSONAL="$(cd "${ROOT}/.." && pwd)"
SDK_SOURCES="${RENPY_SDK_SOURCES:-${PERSONAL}/sdk-sources}"
PY3_SRC="${RENPY_PY3_SRC:-${SDK_SOURCES}/renpy-8.5.3-sdk}"
PY2_SRC="${RENPY_PY2_SRC:-${SDK_SOURCES}/renpy-7.8.7-sdk}"
DEST_ROOT="${POPULATE_DEST_ROOT:-${ROOT}}"
PY3_DEST="${DEST_ROOT}/sdk/py3-8.5.3"
PY2_DEST="${DEST_ROOT}/sdk/py2-7.8.7"

die() { echo "populate-sdk: $*" >&2; exit 1; }

PY3_ONLY=false
PY2_ONLY=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --py3-only) PY3_ONLY=true; shift ;;
        --py2-only) PY2_ONLY=true; shift ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--py3-only] [--py2-only]"
            echo "Set FORCE_POPULATE_SDK=1 to overwrite an existing Linux runtime."
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
done

_pop_plat_dir() {
    case "$(uname -s)" in
        Darwin)
            if [[ -d "${1}/lib/py3-darwin-arm64" ]]; then
                echo "py3-darwin-arm64"
            else
                echo "py3-darwin-x86_64"
            fi
            ;;
        Linux)
            case "$(uname -m)" in
                i686|i386) echo "py3-linux-i686" ;;
                *) echo "py3-linux-x86_64" ;;
            esac
            ;;
        *) echo "py3-linux-x86_64" ;;
    esac
}

_dest_py3_usable() {
    local dest="$1" plat
    plat="$(_pop_plat_dir "$dest")"
    [[ -x "${dest}/lib/${plat}/python" || -x "${dest}/lib/${plat}/python.real" ]]
}

_src_py3_usable() {
    local src="$1" plat
    plat="$(_pop_plat_dir "$src")"
    [[ -x "${src}/lib/${plat}/python" || -x "${src}/lib/${plat}/python.real" ]]
}

_copy_tree_if_missing() {
    local src="$1" dest="$2" label="$3"
    if [[ ! -d "$src" ]]; then
        return 0
    fi
    if [[ -d "$dest" ]] && [[ "${FORCE_POPULATE_SDK:-}" != 1 ]]; then
        echo "  = lib/${label} (keep existing)"
        return 0
    fi
    rm -rf "$dest"
    cp -a "$src" "$dest"
    echo "  + lib/${label}"
}

copy_py3() {
    [[ -d "$PY3_SRC" ]] || {
        echo "  skip py3 (source missing: ${PY3_SRC})"
        return 0
    }
    if ! _src_py3_usable "$PY3_SRC"; then
        echo "  skip py3 (source has no Linux/macOS python: ${PY3_SRC})"
        return 0
    fi
    if _dest_py3_usable "$PY3_DEST" && [[ "${FORCE_POPULATE_SDK:-}" != 1 ]]; then
        echo "  keep py3 (sdk/py3-8.5.3 already has Linux runtime; set FORCE_POPULATE_SDK=1 to overwrite)"
        return 0
    fi

    mkdir -p "${PY3_DEST}/lib"
    for item in renpy.sh renpy.py LICENSE.txt; do
        [[ -f "${PY3_SRC}/${item}" ]] && cp -a "${PY3_SRC}/${item}" "${PY3_DEST}/"
    done
    if [[ -d "${PY3_SRC}/renpy" ]]; then
        if [[ ! -d "${PY3_DEST}/renpy" || "${FORCE_POPULATE_SDK:-}" == 1 ]]; then
            rm -rf "${PY3_DEST}/renpy"
            cp -a "${PY3_SRC}/renpy" "${PY3_DEST}/renpy"
        fi
    fi
    for libpart in python3.12 py3-linux-x86_64 py3-linux-i686 py3-darwin-x86_64 py3-darwin-arm64; do
        _copy_tree_if_missing \
            "${PY3_SRC}/lib/${libpart}" \
            "${PY3_DEST}/lib/${libpart}" \
            "$libpart"
    done
    chmod +x "${PY3_DEST}/renpy.sh" 2>/dev/null || true
    find "${PY3_DEST}/lib" -name python -type f -exec chmod +x {} + 2>/dev/null || true
}

copy_py2() {
    [[ -d "$PY2_SRC" ]] || {
        echo "  skip py2 (source missing: ${PY2_SRC})"
        return 0
    }
    local plat="linux-x86_64"
    case "$(uname -m)" in
        i686|i386) plat="linux-i686" ;;
    esac
    if [[ ! -x "${PY2_SRC}/lib/py2-${plat}/python" && ! -x "${PY2_SRC}/lib/py2-${plat}/python.real" ]]; then
        echo "  skip py2 (source has no lib/py2-${plat}/python: ${PY2_SRC})"
        return 0
    fi
    if [[ -x "${PY2_DEST}/lib/py2-${plat}/python" || -x "${PY2_DEST}/lib/py2-${plat}/python.real" ]] &&
        [[ "${FORCE_POPULATE_SDK:-}" != 1 ]]; then
        echo "  keep py2 (sdk/py2-7.8.7 already has Linux runtime; set FORCE_POPULATE_SDK=1 to overwrite)"
        return 0
    fi

    mkdir -p "${PY2_DEST}/lib"
    for item in renpy.sh renpy.py LICENSE.txt; do
        [[ -f "${PY2_SRC}/${item}" ]] && cp -a "${PY2_SRC}/${item}" "${PY2_DEST}/"
    done
    if [[ -d "${PY2_SRC}/renpy" ]]; then
        if [[ ! -d "${PY2_DEST}/renpy" || "${FORCE_POPULATE_SDK:-}" == 1 ]]; then
            rm -rf "${PY2_DEST}/renpy"
            cp -a "${PY2_SRC}/renpy" "${PY2_DEST}/renpy"
        fi
    fi
    for libpart in python2.7 py2-linux-x86_64 py2-linux-i686 py2-darwin-x86_64; do
        _copy_tree_if_missing \
            "${PY2_SRC}/lib/${libpart}" \
            "${PY2_DEST}/lib/${libpart}" \
            "$libpart"
    done
    chmod +x "${PY2_DEST}/renpy.sh" 2>/dev/null || true
    find "${PY2_DEST}/lib" -name python -type f -exec chmod +x {} + 2>/dev/null || true
}

echo "UnRen-Desktop: populating SDK runtimes"
if [[ "$PY2_ONLY" != true ]]; then
    echo "  py3 source: ${PY3_SRC} -> ${PY3_DEST}"
    copy_py3
fi
if [[ "$PY3_ONLY" != true ]]; then
    echo "  py2 source: ${PY2_SRC} -> ${PY2_DEST}"
    copy_py2
fi
echo "Done."
