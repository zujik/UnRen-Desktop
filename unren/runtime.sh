# SDK runtime helpers (download fallback — populate-sdk.sh is preferred)

sdk_runtime_present() {
    local slice
    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        local sdk_root lib_dir
        sdk_root="$(_unren_sdk_slice_dir "$slice")"
        lib_dir="$(_unren_sdk_lib_dir "$sdk_root" 3 "$(_unren_renpy_platform)")" && \
            _unren_sdk_lib_usable "$lib_dir" && return 0
        lib_dir="$(_unren_sdk_lib_dir "$sdk_root" 2 "$(_unren_renpy_platform)")" && \
            _unren_sdk_lib_usable "$lib_dir" && return 0
    done < <(printf '%s\n' py3-8.5.3 py2-7.8.7 py2-6.99.14.3 py2-5.6.7)
    return 1
}

sdk_renpy_launcher() {
    local sdk_root="$1"
    if [[ -x "${sdk_root}/renpy.sh" ]]; then
        echo "${sdk_root}/renpy.sh"
    elif [[ -f "${sdk_root}/renpy.py" ]]; then
        echo "${sdk_root}/renpy.py"
    fi
}
