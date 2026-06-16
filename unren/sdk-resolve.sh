# Pick bundled Ren'Py SDK slice by game era (2005–present)

_unren_read_script_version_txt() {
    local f content major
    for f in "$@"; do
        [[ -f "$f" ]] || continue
        content="$(head -1 "$f" 2>/dev/null | tr -d '\r')"
        [[ -n "$content" ]] || continue
        if [[ "$content" =~ \([[:space:]]*([0-9]+) ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
            return 0
        fi
        if [[ "$content" =~ ^[[:space:]]*([0-9]+) ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
            return 0
        fi
    done
    return 1
}

_unren_is_rpc3_game() {
    local app="${1:-$UNREN_APP}" rc
    [[ -n "$app" && -f "${DETECT_RPYC_VERSION:-}" ]] || return 1
    pushd "$app" >/dev/null || return 1
    set +e
    env -u PYTHONHOME -u PYTHONPATH python3 "${DETECT_RPYC_VERSION}" >/dev/null 2>&1
    rc=$?
    set -e
    popd >/dev/null || true
    [[ "$rc" -eq 1 ]]
}

_unren_script_version_major_from_app() {
    local app="$1" sv detected f

    if sv="$(_unren_read_script_version_txt \
        "${app}/game/script_version.txt" \
        "${app}/script_version.txt")"; then
        printf '%s\n' "$sv"
        return 0
    fi

    for f in \
        "${app}/game/script_version.rpy" \
        "${app}/game/script_version.rpy.unren-rpc3" \
        "${app}/script_version.rpy" \
        "${app}/script_version.txt"; do
        [[ -f "$f" ]] || continue
        sv="$(grep -m1 'config\.script_version' "$f" 2>/dev/null \
            | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\).*/\1/p')"
        if [[ -n "$sv" ]]; then
            printf '%s\n' "$sv"
            return 0
        fi
    done

    if [[ -f "${app}/renpy/vc_version.py" ]]; then
        sv="$(grep -m1 '^version' "${app}/renpy/vc_version.py" 2>/dev/null \
            | sed -n "s/.*['\"]\\([0-9][0-9]*\\)\\..*/\\1/p")"
        [[ -n "$sv" ]] && printf '%s\n' "$sv" && return 0
        sv="$(perl -nle 'if (/\b(?:vc_)?version\s*=\s*[\x22\x27]?([0-9]+)/) { print $1; exit }' \
            "${app}/renpy/vc_version.py" 2>/dev/null)"
        [[ -n "$sv" ]] && printf '%s\n' "$sv" && return 0
    fi

    if [[ -f "${app}/renpy/__init__.py" ]]; then
        sv="$(grep -m1 'version_tuple' "${app}/renpy/__init__.py" 2>/dev/null \
            | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\).*/\1/p')"
        [[ -n "$sv" ]] && printf '%s\n' "$sv" && return 0
        sv="$(perl -ne '
            if (/version_tuple\s*=\s*\(\s*(\d+)/) { push @v, $1 }
            END { if (@v) { @v = sort { $b <=> $a } @v; print $v[0] } }
        ' "${app}/renpy/__init__.py" 2>/dev/null)"
        [[ -n "$sv" ]] && printf '%s\n' "$sv" && return 0
    fi

    if [[ -f "${DETECT_RENPY_VERSION:-}" ]]; then
        detected="$(env -u PYTHONHOME -u PYTHONPATH python3 \
            "${DETECT_RENPY_VERSION}" "${app}" 2>/dev/null || true)"
        if [[ "$detected" =~ ^[678]$ ]]; then
            printf '%s\n' "$detected"
            return 0
        fi
    fi

    printf '0\n'
}

_unren_sdk_slice_dir() {
    local slice=$1 app="${2:-}"
    if [[ -n "$app" ]]; then
        app="$(cd -P "$app" 2>/dev/null && pwd)" || app="$2"
        if [[ -d "${app}/sdk/${slice}" && ( -f "${app}/sdk/${slice}/renpy.py" || -d "${app}/sdk/${slice}/renpy" ) ]]; then
            printf '%s\n' "${app}/sdk/${slice}"
            return 0
        fi
    fi
    printf '%s\n' "${UNREN_ROOT}/sdk/${slice}"
}

_unren_sdk_slice_py_major() {
    local slice="$1"
    case "$slice" in
        py3-*) printf '3\n' ;;
        py2-*) printf '2\n' ;;
        *) printf '2\n' ;;
    esac
}

_unren_sdk_slice_matches_py_major() {
    local slice="$1" py_major="$2"
    local slice_py

    [[ -n "$py_major" ]] || return 0
    slice_py="$(_unren_sdk_slice_py_major "$slice")"
    [[ "$slice_py" == "$py_major" ]]
}

_unren_pythonhome_has_stdlib() {
    local pyhome="$1"
    [[ -n "$pyhome" && -d "$pyhome" ]] && {
        [[ -f "${pyhome}/site.py" || -f "${pyhome}/site.pyc" || -d "${pyhome}/encodings" ]]
    }
}

_unren_sdk_runtime_usable() {
    local slice="$1" sdk_root="$2" lib_dir="$3"
    local phome

    _unren_sdk_lib_usable "$lib_dir" || return 1
    phome="$(_unren_sdk_pythonhome "$sdk_root" "$lib_dir")"
    if _unren_pythonhome_has_stdlib "$phome"; then
        return 0
    fi
    # Ren'Py 7/8 SDK: embedded python carries stdlib; do not require PYTHONHOME.
    case "$slice" in
        py3-*|py2-*)
            [[ -x "${lib_dir}/python" || -x "${lib_dir}/python.real" || -x "${lib_dir}/renpy" ]]
            ;;
        *) return 1 ;;
    esac
}

_unren_sdk_slice_exists() {
    local slice=$1 app="${2:-}" dir
    if [[ -n "$app" && -d "${app}/sdk/${slice}" ]]; then
        [[ -f "${app}/sdk/${slice}/renpy.py" || -d "${app}/sdk/${slice}/renpy" ]] && return 0
    fi
    dir="$(_unren_sdk_slice_dir "$slice")"
    [[ -d "$dir" && ( -f "${dir}/renpy.py" || -d "${dir}/renpy" ) ]]
}

_unren_sdk_layout() {
    local sdk_root=$1
    if [[ -d "${sdk_root}/lib/py3-linux-x86_64" || -d "${sdk_root}/lib/py2-linux-x86_64" ]]; then
        printf 'modern\n'
    elif [[ -d "${sdk_root}/lib/linux-x86_64" || -d "${sdk_root}/lib/linux-i686" ]]; then
        printf 'renpy6\n'
    elif [[ -d "${sdk_root}/lib/linux-x86" ]]; then
        printf 'renpy5\n'
    else
        printf 'none\n'
    fi
}

_unren_sdk_platform_name() {
    local platform="$1"
    case "$platform" in
        mac-universal|*-darwin*|Darwin-*)
            if [[ -d "${2}/lib/py3-darwin-arm64" || -d "${2}/lib/py2-darwin-arm64" ]]; then
                printf 'darwin-arm64\n'
            else
                printf 'darwin-x86_64\n'
            fi
            ;;
        linux-i686|*-i686|*-i386)
            printf 'linux-i686\n'
            ;;
        linux-x86_64|*-x86_64|amd64|Linux-*)
            if [[ -d "${2}/lib/linux-x86_64" ]]; then
                printf 'linux-x86_64\n'
            elif [[ -d "${2}/lib/linux-x86" ]]; then
                printf 'linux-x86\n'
            else
                printf 'linux-x86_64\n'
            fi
            ;;
        *)
            printf '%s\n' "$platform"
            ;;
    esac
}

_unren_sdk_lib_dir() {
    local sdk_root=$1 py_major=$2 platform=$3
    local layout plat_dir

    layout="$(_unren_sdk_layout "$sdk_root")"
    plat_dir="$(_unren_sdk_platform_name "$platform" "$sdk_root")"

    case "$layout" in
        modern)
            printf '%s\n' "${sdk_root}/lib/py${py_major}-${plat_dir}"
            ;;
        renpy6)
            printf '%s\n' "${sdk_root}/lib/${plat_dir}"
            ;;
        renpy5)
            printf '%s\n' "${sdk_root}/lib/linux-x86"
            ;;
        *)
            return 1
            ;;
    esac
}

_unren_sdk_lib_usable() {
    local lib_dir=$1
    [[ -d "$lib_dir" ]] && {
        [[ -x "${lib_dir}/python" || -x "${lib_dir}/python.real" || -x "${lib_dir}/renpy" ]]
    }
}

_unren_sdk_pythonhome() {
    local sdk_root=$1 lib_dir=$2
    local layout plat_pyhome

    layout="$(_unren_sdk_layout "$sdk_root")"
    case "$layout" in
        modern)
            # py3: optional PYTHONHOME for extras. py2: embedded python — never set
            # PYTHONHOME to sdk/lib/python2.7 (breaks fake-site bootstrap).
            if [[ -d "${sdk_root}/lib/python3.12" ]]; then
                printf '%s\n' "${sdk_root}/lib/python3.12"
            fi
            ;;
        renpy6)
            plat_pyhome="${lib_dir}/lib/python2.7"
            if [[ -d "$plat_pyhome" ]]; then
                printf '%s\n' "$plat_pyhome"
            elif [[ -d "${sdk_root}/lib/pythonlib2.7" ]]; then
                printf '%s\n' "${sdk_root}/lib/pythonlib2.7"
            fi
            ;;
        renpy5)
            printf '%s\n' "${lib_dir}/lib/python2.3"
            ;;
    esac
}

_unren_sdk_python_runner() {
    local lib_dir=$1 sdk_root=$2
    if [[ -x "${lib_dir}/python" ]]; then
        printf '%s\n' "${lib_dir}/python"
    elif [[ -x "${lib_dir}/python.real" ]]; then
        printf '%s\n' "${lib_dir}/python.real"
    elif [[ -x "${sdk_root}/lib/python" ]]; then
        printf '%s\n' "${sdk_root}/lib/python"
    fi
}

_unren_sdk_ld_library_path() {
    local lib_dir=$1 sdk_root=$2
    local layout
    layout="$(_unren_sdk_layout "$sdk_root")"
    case "$layout" in
        renpy6|renpy5)
            printf '%s:%s\n' "$lib_dir" "${lib_dir}/lib"
            ;;
        *)
            printf '%s\n' "$lib_dir"
            ;;
    esac
}

_unren_sdk_py_args() {
    local sdk_root=$1
    local layout
    layout="$(_unren_sdk_layout "$sdk_root")"
    case "$layout" in
        renpy6|renpy5) printf '%s\n' '-EO' ;;
        *) printf '\n' ;;
    esac
}

_unren_sdk_fallback_chain() {
    local app="$1" major
    local -a wanted=() slice

    if _unren_is_rpc3_game "$app"; then
        wanted=(py2-6.99.14.3 py2-7.8.7 py2-5.6.7)
    else
        major="$(_unren_script_version_major_from_app "$app")"
        case "$major" in
            8|9|10)
                wanted=(py3-8.5.3)
                ;;
            7)
                wanted=(py2-7.8.7 py2-6.99.14.3)
                ;;
            6)
                wanted=(py2-6.99.14.3 py2-7.8.7)
                ;;
            5)
                wanted=(py2-5.6.7 py2-6.99.14.3 py2-7.8.7)
                ;;
            4|3|2|1)
                wanted=(py2-5.6.7 py2-6.99.14.3)
                ;;
            *)
                wanted=(py3-8.5.3 py2-7.8.7 py2-6.99.14.3 py2-5.6.7)
                ;;
        esac
    fi

    for slice in "${wanted[@]}"; do
        printf '%s\n' "$slice"
    done
}

_unren_resolve_sdk_runtime() {
    local app="$1" py_major=$2 platform=$3
    local _root_var="$4" _lib_var="$5"
    local slice resolved_root resolved_lib

    eval "$_root_var=\"\""
    eval "$_lib_var=\"\""

    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        local slice_py phome
        _unren_sdk_slice_matches_py_major "$slice" "$py_major" || continue
        resolved_root="$(_unren_sdk_slice_dir "$slice" "$app")"
        slice_py="$(_unren_sdk_slice_py_major "$slice")"
        resolved_lib="$(_unren_sdk_lib_dir "$resolved_root" "$slice_py" "$platform")" || continue
        _unren_sdk_lib_usable "$resolved_lib" || continue
        _unren_sdk_runtime_usable "$slice" "$resolved_root" "$resolved_lib" || continue
        eval "$_root_var=\"\$resolved_root\""
        eval "$_lib_var=\"\$resolved_lib\""
        return 0
    done < <(_unren_sdk_fallback_chain "$app")

    return 1
}

# Ren'Py py2 SDK stdlib omits deprecated md5.py; legacy games still import it.
_unren_ensure_py2_stdlib_shims() {
    local app="${1:-$UNREN_APP}" lib_dir="${2:-}" shim_src pyhome sdk_root

    shim_src="${UNREN_ROOT}/sdk/stdlib-shims/py2/md5.py"
    [[ -f "$shim_src" ]] || return 0

    if [[ -n "$lib_dir" && "$lib_dir" == *"/sdk/"* ]]; then
        sdk_root="${lib_dir%%/lib/*}"
        pyhome="$(_unren_sdk_pythonhome "$sdk_root" "$lib_dir" 2>/dev/null || true)"
        if [[ -n "$pyhome" && -d "$pyhome" ]] && {
            [[ -f "${pyhome}/_md5.so" || -f "${pyhome}/lib-dynload/_md5.so" ]]
        } && [[ ! -f "${pyhome}/md5.py" ]]; then
            cp "$shim_src" "${pyhome}/md5.py"
        fi
    fi

    for pyhome in \
        "${app}/sdk/py2-6.99.14.3/lib/linux-x86_64/lib/python2.7" \
        "${app}/sdk/py2-6.99.14.3/lib/linux-i686/lib/python2.7" \
        "${app}/sdk/py2-6.99.14.3/lib/darwin-x86_64/lib/python2.7" \
        "${app}/sdk/py2-7.8.7/lib/python2.7" \
        "${UNREN_ROOT}/sdk/py2-6.99.14.3/lib/linux-x86_64/lib/python2.7" \
        "${UNREN_ROOT}/sdk/py2-6.99.14.3/lib/linux-i686/lib/python2.7" \
        "${UNREN_ROOT}/sdk/py2-6.99.14.3/lib/darwin-x86_64/lib/python2.7" \
        "${UNREN_ROOT}/sdk/py2-7.8.7/lib/python2.7"; do
        [[ -d "$pyhome" && ( -f "${pyhome}/_md5.so" || -f "${pyhome}/lib-dynload/_md5.so" ) ]] || continue
        [[ -f "${pyhome}/md5.py" ]] || cp "$shim_src" "${pyhome}/md5.py"
    done
}
