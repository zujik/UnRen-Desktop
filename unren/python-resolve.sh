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
            arm64|aarch64)
                if [[ -d "${sdk_root}/lib/py${py_major}-mac-universal" ]]; then
                    echo "${sdk_root}/lib/py${py_major}-mac-universal"
                else
                    echo "${sdk_root}/lib/py${py_major}-darwin-arm64"
                fi
                ;;
            *)
                if [[ -d "${sdk_root}/lib/py${py_major}-mac-universal" ]]; then
                    echo "${sdk_root}/lib/py${py_major}-mac-universal"
                else
                    echo "${sdk_root}/lib/py${py_major}-darwin-x86_64"
                fi
                ;;
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
    find "$root" -type d -name encodings \
        ! -path "*/sdk/*" \
        ! -path "*/.sdk-sources-cache/*" \
        ! -path "*/pythonlib2.7/*" \
        2>/dev/null | head -1
}

_unren_encodings_dir_usable() {
    local py_bin="$1" enc_dir="$2" pyhome
    [[ -n "$py_bin" && -n "$enc_dir" && -d "$enc_dir" ]] || return 1
    pyhome="${enc_dir%/encodings}"
    env -u PYTHONHOME -u PYTHONPATH PYTHONHOME="$pyhome" \
        "$py_bin" -c "import encodings" >/dev/null 2>&1
}

_unren_find_game_encodings_dir() {
    local py_bin="$1" app="$2" enc_dir candidate
    local -a candidates=()
    local py_dir
    py_dir="$(dirname "$py_bin")"

    # Stdlib beside the runtime binary (Ren'Py 6/7 Linux/mac layout).
    candidates+=("${py_dir}/lib/python2.7")
    candidates+=("${py_dir}")
    candidates+=("${app}/lib/linux-x86_64/lib/python2.7")
    candidates+=("${app}/lib/linux-i686/lib/python2.7")
    candidates+=("${app}/lib/darwin-x86_64/lib/python2.7")
    candidates+=("${app}/lib/darwin-arm64/lib/python2.7")
    candidates+=("${app}/lib/python3.12")
    candidates+=("${app}/lib/python3.11")
    candidates+=("${app}/lib/python3.9")
    candidates+=("${app}/lib/python2.7")
    # pythonlib2.7 is for Ren'Py 5/6 SDK trees, not PC lib/linux-x86_64 runtimes.
    case "$py_bin" in
        */pythonlib2.7/*|*/sdk/py2-6.99.14.3/*)
            candidates+=("${app}/lib/pythonlib2.7")
            ;;
    esac

    for candidate in "${candidates[@]}"; do
        [[ -d "${candidate}/encodings" ]] || continue
        if _unren_encodings_dir_usable "$py_bin" "${candidate}/encodings"; then
            printf '%s\n' "${candidate}/encodings"
            return 0
        fi
    done

    enc_dir="$(_unren_find_encodings_dir "$py_dir")"
    if [[ -n "$enc_dir" ]] && _unren_encodings_dir_usable "$py_bin" "$enc_dir"; then
        printf '%s\n' "$enc_dir"
        return 0
    fi

    enc_dir="$(_unren_find_encodings_dir "$app")"
    if [[ -n "$enc_dir" ]] && _unren_encodings_dir_usable "$py_bin" "$enc_dir"; then
        printf '%s\n' "$enc_dir"
        return 0
    fi

    return 1
}

_unren_configure_python_env() {
    local py_bin="$1"
    local extra_paths=("${@:2}")

    local enc_dir=""
    if ! enc_dir="$(_unren_find_game_encodings_dir "$py_bin" "${UNREN_APP}")"; then
        enc_dir=""
    fi

    if [[ -n "$enc_dir" ]]; then
        local pyhome="${enc_dir%/encodings}"
        if env -u PYTHONHOME -u PYTHONPATH PYTHONHOME="$pyhome" \
            "$py_bin" -c "import encodings" >/dev/null 2>&1; then
            PYTHONHOME="$pyhome"
            PYTHONPATH="$pyhome"
            for p in "${extra_paths[@]}"; do
                [[ -n "$p" ]] && PYTHONPATH="${PYTHONPATH}:${p}"
            done
            export PYTHONHOME PYTHONPATH
        fi
    fi

    local gamepyver
    gamepyver=$("$py_bin" --version 2>&1 | awk '{gsub(/[^[:digit:]]+/, " "); printf("%d%03d%03d\n", $1, $2, $3)}') || gamepyver=0
    PYARGS=()
    if [[ ${gamepyver::1} == 3 ]] && ((gamepyver < MIN_GAME_PYVER)); then
        PYARGS=(-EO)
    fi
}

_unren_configure_sdk_python_env() {
    local py_bin="$1" sdk_root="$2" sdk_lib="$3"
    local phome py_args ld_path

    phome="$(_unren_sdk_pythonhome "$sdk_root" "$sdk_lib")"
    if [[ -n "$phome" ]]; then
        PYTHONHOME="$phome"
        PYTHONPATH="$phome"
        [[ -d "${sdk_root}/renpy" ]] && PYTHONPATH="${PYTHONPATH}:${sdk_root}/renpy"
        export PYTHONHOME PYTHONPATH
    else
        unset PYTHONHOME PYTHONPATH
    fi

    PYARGS=()
    py_args="$(_unren_sdk_py_args "$sdk_root")"
    [[ -n "$py_args" ]] && PYARGS=("$py_args")

    ld_path="$(_unren_sdk_ld_library_path "$sdk_lib" "$sdk_root")"
    if [[ -n "$ld_path" ]]; then
        export LD_LIBRARY_PATH="${ld_path}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
    fi
}

_unren_find_app_bundle_python() {
    local target="$1" root cand
    for root in \
        "${target}/Contents/MacOS" \
        "${target}/Contents/Resources/autorun" \
        "${target}/Contents/Resources"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r cand; do
            [[ -n "$cand" && -f "$cand" ]] || continue
            chmod -f +x "$cand" 2>/dev/null || true
            printf '%s\n' "$cand"
            return 0
        done < <(find "$root" \( -name python -o -name python.real \) -type f 2>/dev/null | head -1)
    done
    return 1
}

_unren_find_game_tree_python() {
    local app="$1" py_major="${2:-}" lib_dir
    local -a candidates=()

    if [[ -n "$py_major" ]]; then
        candidates+=(
            "${app}/lib/py${py_major}-mac-universal/python"
            "${app}/lib/py${py_major}-mac-universal/python.real"
            "${app}/lib/py${py_major}-darwin-arm64/python"
            "${app}/lib/py${py_major}-darwin-arm64/python.real"
            "${app}/lib/py${py_major}-darwin-x86_64/python"
            "${app}/lib/py${py_major}-linux-x86_64/python"
            "${app}/lib/py${py_major}-linux-x86_64/python.real"
        )
    fi
    candidates+=(
        "${app}/lib/mac-universal/python"
        "${app}/lib/darwin-arm64/python"
        "${app}/lib/darwin-x86_64/python"
        "${app}/lib/linux-x86_64/python"
    )

    for lib_dir in "${candidates[@]}"; do
        [[ -x "$lib_dir" ]] || continue
        printf '%s\n' "$lib_dir"
        return 0
    done

    find "${app}/lib" -path "*$(_unren_machine)*" -type f -name python 2>/dev/null | head -1
}

_unren_python_imports_encodings() {
    local py_bin="$1"
    if [[ -n "${PYTHONHOME:-}" ]]; then
        env PYTHONHOME="$PYTHONHOME" PYTHONPATH="${PYTHONPATH:-}" \
            "$py_bin" -c "import encodings" >/dev/null 2>&1
    else
        env -u PYTHONHOME -u PYTHONPATH "$py_bin" -c "import encodings" >/dev/null 2>&1
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
    local app="$1" platform="$2" sv renpy_major

    if _unren_is_rpc3_game "$app"; then
        printf '2\n'
        return 0
    fi

    renpy_major="$(_unren_script_version_major_from_app "$app")"
    if (( renpy_major >= 8 )); then
        printf '3\n'
        return 0
    fi

    if (( renpy_major >= 1 && renpy_major < 8 )); then
        printf '2\n'
        return 0
    fi

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
    UNREN_SDK_LIB=""
    PYARGS=()

    local py_major platform autorun

    platform="$(_unren_renpy_platform)"
    if ! autorun="$(_unren_renpy_autorun_root "${UNREN_TARGET}" 2>/dev/null)"; then
        unren_die "Unable to determine Ren'Py game layout in: ${UNREN_TARGET}"
    fi
    UNREN_APP="$autorun"
    UNREN_GAME="${UNREN_APP}/game"
    py_major="$(_unren_guess_python_major "$UNREN_APP" "$platform")"

    if [[ "${UNREN_TARGET}" == *.app || -e "${UNREN_TARGET}/Contents/MacOS" ]]; then
        UNREN_PYTHON="$(_unren_find_app_bundle_python "${UNREN_TARGET}" || true)"
        [[ -z "$UNREN_PYTHON" ]] && \
            UNREN_PYTHON="$(_unren_find_game_tree_python "$UNREN_APP" "$py_major" || true)"
    else
        UNREN_PYTHON="$(_unren_find_game_tree_python "$UNREN_APP" "$py_major" || true)"
    fi

    if [[ -n "$UNREN_PYTHON" ]]; then
        chmod -f +x "$UNREN_PYTHON" 2>/dev/null || true
        if is_osx; then
            xattr -rd com.apple.quarantine "$UNREN_PYTHON" 2>/dev/null || true
            xattr -rd com.apple.quarantine "${UNREN_TARGET}" 2>/dev/null || true
        fi
    fi

    if [[ -n "$UNREN_PYTHON" && -x "$UNREN_PYTHON" ]]; then
        if _unren_python_imports_encodings "$UNREN_PYTHON"; then
            _unren_configure_python_env "$UNREN_PYTHON" "${UNREN_APP}" || true
            return 0
        fi
        _unren_configure_python_env "$UNREN_PYTHON" "${UNREN_APP}" || true
        if _unren_python_imports_encodings "$UNREN_PYTHON"; then
            return 0
        fi
        UNREN_PYTHON=""
    fi

    # Fallback: bundled SDK runtimes shipped with UnRen-Desktop
    local sdk_root sdk_py sdk_lib

    if is_osx; then
        xattr -rd com.apple.quarantine "${UNREN_ROOT}/sdk" 2>/dev/null || true
    fi

    if _unren_resolve_sdk_runtime "$UNREN_APP" "$py_major" "$platform" sdk_root sdk_lib; then
        sdk_py="$(_unren_sdk_python_runner "$sdk_lib" "$sdk_root")"
        if [[ -z "$sdk_py" || ! -x "$sdk_py" ]]; then
            sdk_py="${sdk_lib}/python"
        fi
        if [[ ! -x "$sdk_py" ]]; then
            unren_die "Bundled SDK Python missing under ${sdk_lib}"
        fi
        UNREN_SDK_ROOT="${sdk_root}"
        UNREN_SDK_LIB="${sdk_lib}"
        UNREN_PYTHON="${sdk_py}"
        _unren_configure_sdk_python_env "$UNREN_PYTHON" "${sdk_root}" "${sdk_lib}"
        return 0
    fi

    if _unren_try_auto_fetch_sdk_slices "$UNREN_APP" "$py_major" "$platform" &&
        _unren_resolve_sdk_runtime "$UNREN_APP" "$py_major" "$platform" sdk_root sdk_lib; then
        sdk_py="$(_unren_sdk_python_runner "$sdk_lib" "$sdk_root")"
        [[ -z "$sdk_py" || ! -x "$sdk_py" ]] && sdk_py="${sdk_lib}/python"
        if [[ ! -x "$sdk_py" ]]; then
            unren_die "Bundled SDK Python missing under ${sdk_lib}"
        fi
        UNREN_SDK_ROOT="${sdk_root}"
        UNREN_SDK_LIB="${sdk_lib}"
        UNREN_PYTHON="${sdk_py}"
        _unren_configure_sdk_python_env "$UNREN_PYTHON" "${sdk_root}" "${sdk_lib}"
        return 0
    fi

    unren_die "No game Python found and no usable bundled SDK runtime in sdk/. See sdk/README.md
  (py${py_major}, platform ${platform}; refresh with: rm -rf \"${UNREN_ROOT}/../unren-desktop\" and re-run)"
}

# rpatool is Python 3 — never run it with the game's embedded py2 SDK interpreter.
unren_resolve_rpatool_python() {
    local py
    if [[ -n "${UNREN_RPA_PYTHON:-}" && -x "${UNREN_RPA_PYTHON}" ]]; then
        printf '%s\n' "${UNREN_RPA_PYTHON}"
        return 0
    fi

    py="$(command -v python3 2>/dev/null || true)"
    if [[ -n "$py" ]]; then
        printf '%s\n' "$py"
        return 0
    fi

    unren_die "rpatool needs python3 (system python3 not found). Set UNREN_RPA_PYTHON to a Python 3 interpreter."
}

_unren_python_has_multiprocessing() {
    local py="$1"
    env -u PYTHONHOME -u PYTHONPATH \
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
