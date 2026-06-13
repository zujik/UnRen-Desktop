# Resolve game layout and Python interpreter (game first, bundled SDK second)

_unren_machine() {
    uname -m
}

_unren_sdk_platform_dir() {
    local py_major="$1"
    local sdk_root="$2"
    local machine
    machine="$(_unren_machine)"

    if is_osx; then
        case "$machine" in
            arm64|aarch64) echo "${sdk_root}/lib/py${py_major}-darwin-arm64" ;;
            *) echo "${sdk_root}/lib/py${py_major}-darwin-x86_64" ;;
        esac
    else
        case "$machine" in
            i686|i386) echo "${sdk_root}/lib/py${py_major}-linux-i686" ;;
            *) echo "${sdk_root}/lib/py${py_major}-linux-x86_64" ;;
        esac
    fi
}

_unren_find_encodings_dir() {
    local root="$1"
    find "$root" -type d -name encodings 2>/dev/null | head -1
}

_unren_configure_python_env() {
    local py_bin="$1"
    local extra_paths=("${@:2}")

    local enc_dir
    enc_dir="$(_unren_find_encodings_dir "$(dirname "$py_bin")")"
    if [[ -z "$enc_dir" ]]; then
        enc_dir="$(_unren_find_encodings_dir "$UNREN_APP")"
    fi

    if [[ -n "$enc_dir" ]]; then
        PYTHONHOME="$(dirname "$enc_dir")"
        PYTHONPATH="$(dirname "$enc_dir")"
        for p in "${extra_paths[@]}"; do
            [[ -n "$p" ]] && PYTHONPATH="${PYTHONPATH}:${p}"
        done
        export PYTHONHOME PYTHONPATH
    fi

    local gamepyver
    gamepyver=$("$py_bin" --version 2>&1 | awk '{gsub(/[^[:digit:]]+/, " "); printf("%d%03d%03d\n", $1, $2, $3)}')
    PYARGS=()
    if [[ ${gamepyver::1} == 3 ]] && ((gamepyver < MIN_GAME_PYVER)); then
        PYARGS=(-EO)
    fi
}

_unren_renpy_platform() {
    if [[ -n "${RENPY_PLATFORM:-}" ]]; then
        printf '%s\n' "$RENPY_PLATFORM"
        return 0
    fi

    local raw
    raw="$(uname -s)-$(uname -m)"
    case "$raw" in
        Darwin-*|mac-*)
            printf '%s\n' "mac-universal"
            ;;
        *-x86_64|amd64)
            printf '%s\n' "linux-x86_64"
            ;;
        *-i*86)
            printf '%s\n' "linux-i686"
            ;;
        Linux-*)
            printf '%s\n' "linux-$(uname -m)"
            ;;
        *)
            printf '%s\n' "$raw"
            ;;
    esac
}

_unren_guess_python_major() {
    local app="$1" platform="$2" sv

    if compgen -G "${app}/lib/py3-${platform}" >/dev/null ||
       compgen -G "${app}/lib/py3-*" >/dev/null ||
       [[ -d "${app}/lib/python3.12" || -d "${app}/lib/python3.9" || -d "${app}/lib/python3.11" ]]; then
        printf '3\n'
        return 0
    fi

    if compgen -G "${app}/lib/py2-${platform}" >/dev/null ||
       compgen -G "${app}/lib/py2-*" >/dev/null ||
       [[ -d "${app}/lib/python2.7" || -d "${app}/lib/pythonlib2.7" ]] ||
       compgen -G "${app}/lib/windows-*" >/dev/null; then
        printf '2\n'
        return 0
    fi

    sv="$(grep -rh 'config\.script_version' "${app}/game/script_version.rpy" "${app}/game/script_version.txt" 2>/dev/null \
        | head -1 | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\).*/\1/p')"
    if [[ -n "$sv" ]]; then
        if (( sv >= 8 )); then
            printf '3\n'
        else
            printf '2\n'
        fi
        return 0
    fi

    if [[ -d "${SDK_PY3_DIR}/renpy" ]]; then
        printf '3\n'
        return 0
    fi

    printf '2\n'
}

resolve_game_and_python() {
    UNREN_APP=""
    UNREN_GAME=""
    UNREN_PYTHON=""
    UNREN_SDK_ROOT=""
    PYARGS=()

    # macOS .app bundle
    if [[ -e "${UNREN_TARGET}/Contents/Resources/autorun/renpy" &&
          -e "${UNREN_TARGET}/Contents/Resources/autorun/game" ]]; then
        xattr -rd com.apple.quarantine "${UNREN_TARGET}" 2>/dev/null || true
        UNREN_APP="${UNREN_TARGET}/Contents/Resources/autorun"
        UNREN_GAME="${UNREN_APP}/game"
        UNREN_PYTHON="$(find "${UNREN_TARGET}/Contents/MacOS" -type f -name python 2>/dev/null | head -1)"
    elif [[ -e "${UNREN_TARGET}/renpy" && -e "${UNREN_TARGET}/game" ]]; then
        UNREN_APP="${UNREN_TARGET}"
        UNREN_GAME="${UNREN_TARGET}/game"
        UNREN_PYTHON="$(find "${UNREN_TARGET}/lib" -path "*$(_unren_machine)*" -type f -name python 2>/dev/null | head -1)"
        if [[ -z "$UNREN_PYTHON" ]]; then
            UNREN_PYTHON="$(find "${UNREN_TARGET}/lib" -type f -name python 2>/dev/null | head -1)"
        fi
    else
        unren_die "Unable to determine Ren'Py game layout in: ${UNREN_TARGET}"
    fi

    if [[ -n "$UNREN_PYTHON" ]]; then
        chmod -f +x "$UNREN_PYTHON" 2>/dev/null || true
    fi

    if [[ -n "$UNREN_PYTHON" && -x "$UNREN_PYTHON" ]]; then
        _unren_configure_python_env "$UNREN_PYTHON" "${UNREN_APP}"
        return 0
    fi

    # Fallback: bundled SDK runtimes shipped with UnRen-Desktop
    local py_major sdk_root sdk_py platform
    platform="$(_unren_renpy_platform)"
    py_major="$(_unren_guess_python_major "$UNREN_APP" "$platform")"

    if [[ "$py_major" == 3 && -d "${SDK_PY3_DIR}/renpy" ]]; then
        sdk_root="${SDK_PY3_DIR}"
    elif [[ -d "${SDK_PY2_DIR}/renpy" ]]; then
        py_major=2
        sdk_root="${SDK_PY2_DIR}"
    elif [[ -d "${SDK_PY3_DIR}/renpy" ]]; then
        sdk_root="${SDK_PY3_DIR}"
    else
        unren_die "No game Python found and no bundled SDK runtime in sdk/. Run scripts/populate-sdk.sh"
    fi

    sdk_py="$(_unren_sdk_platform_dir "$py_major" "$sdk_root")/python"
    if [[ ! -x "$sdk_py" ]]; then
        unren_die "Bundled SDK Python missing: ${sdk_py}"
    fi

    UNREN_SDK_ROOT="${sdk_root}"
    UNREN_PYTHON="${sdk_py}"
    _unren_configure_python_env "$UNREN_PYTHON" "${sdk_root}" "${sdk_root}/renpy"
}

_unren_python_has_multiprocessing() {
    local py="$1"
    PYTHONHOME="${PYTHONHOME-}" PYTHONPATH="${PYTHONPATH-}" \
        "$py" -c "import _multiprocessing" 2>/dev/null
}

# unrpyc does not need Ren'Py's embedded Python; prefer an interpreter with working multiprocessing.
unren_resolve_unrpyc_python() {
    if [[ -n "${UNREN_UNRPYC_PYTHON:-}" && -x "${UNREN_UNRPYC_PYTHON}" ]]; then
        printf '%s\n' "${UNREN_UNRPYC_PYTHON}"
        return 0
    fi

    if _unren_python_has_multiprocessing "$UNREN_PYTHON"; then
        printf '%s\n' "$UNREN_PYTHON"
        return 0
    fi

    local py
    py="$(command -v python3 2>/dev/null || true)"
    if [[ -n "$py" ]] && env -u PYTHONHOME -u PYTHONPATH \
        "$py" -c 'import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 9) else 1)' 2>/dev/null; then
        printf '%s\n' "$py"
        return 0
    fi

    printf '%s\n' "$UNREN_PYTHON"
}
