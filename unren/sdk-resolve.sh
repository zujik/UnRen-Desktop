# Pick bundled Ren'Py SDK slice by game era (2005–present)

_unren_script_version_major_from_app() {
    local app="$1" sv
    sv="$(grep -rh 'config\.script_version' \
        "${app}/game/script_version.rpy" "${app}/game/script_version.txt" \
        "${app}/script_version.rpy" "${app}/script_version.txt" 2>/dev/null \
        | head -1 | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\).*/\1/p')"
    if [[ -n "$sv" ]]; then
        printf '%s\n' "$sv"
        return 0
    fi

    if [[ -f "${app}/renpy/vc_version.py" ]]; then
        sv="$(grep -m1 '^version' "${app}/renpy/vc_version.py" 2>/dev/null \
            | sed -n "s/.*['\"]\\([0-9][0-9]*\\)\\..*/\\1/p")"
        [[ -n "$sv" ]] && printf '%s\n' "$sv" && return 0
    fi

    if [[ -f "${app}/renpy/__init__.py" ]]; then
        sv="$(perl -ne 'if (/version_tuple\s*=\s*\(\s*(\d+)/) { print $1; exit }' \
            "${app}/renpy/__init__.py" 2>/dev/null)"
        [[ -n "$sv" ]] && printf '%s\n' "$sv" && return 0
    fi

    printf '0\n'
}

_unren_sdk_slice_dir() {
    printf '%s\n' "${UNREN_ROOT}/sdk/${1}"
}

_unren_sdk_slice_exists() {
    local slice=$1 dir
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
            if [[ -d "${sdk_root}/lib/python3.12" ]]; then
                printf '%s\n' "${sdk_root}/lib/python3.12"
            elif [[ -d "${sdk_root}/lib/python2.7" ]]; then
                printf '%s\n' "${sdk_root}/lib/python2.7"
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

    major="$(_unren_script_version_major_from_app "$app")"
    case "$major" in
        8|9|10)
            wanted=(py3-8.5.3 py2-7.8.7)
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
            wanted=(py2-5.6.7 py2-4.8.10 py2-6.99.14.3)
            ;;
        *)
            wanted=(py3-8.5.3 py2-7.8.7 py2-6.99.14.3 py2-5.6.7)
            ;;
    esac

    for slice in "${wanted[@]}"; do
        _unren_sdk_slice_exists "$slice" && printf '%s\n' "$slice"
    done
}

_unren_resolve_sdk_runtime() {
    local app="$1" py_major=$2 platform=$3
    local -n _root_out=$4
    local -n _lib_out=$5
    local slice sdk_root lib_dir

    _root_out=""
    _lib_out=""

    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        sdk_root="$(_unren_sdk_slice_dir "$slice")"
        lib_dir="$(_unren_sdk_lib_dir "$sdk_root" "$py_major" "$platform")" || continue
        _unren_sdk_lib_usable "$lib_dir" || continue
        _root_out="$sdk_root"
        _lib_out="$lib_dir"
        return 0
    done < <(_unren_sdk_fallback_chain "$app")

    return 1
}
