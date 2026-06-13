# SDK runtime helpers (download fallback — populate-sdk.sh is preferred)

sdk_runtime_present() {
    [[ -x "${SDK_PY3_DIR}/lib/py3-linux-x86_64/python" || -x "${SDK_PY3_DIR}/lib/py3-darwin-x86_64/python" ||
       -x "${SDK_PY2_DIR}/lib/py2-linux-x86_64/python" || -x "${SDK_PY2_DIR}/lib/py2-darwin-x86_64/python" ]]
}

sdk_renpy_launcher() {
    local sdk_root="$1"
    if [[ -x "${sdk_root}/renpy.sh" ]]; then
        echo "${sdk_root}/renpy.sh"
    elif [[ -f "${sdk_root}/renpy.py" ]]; then
        echo "${sdk_root}/renpy.py"
    fi
}
