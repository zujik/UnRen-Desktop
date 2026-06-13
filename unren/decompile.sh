# Decompile .rpyc files with unrpyc (Python 3)

_unren_script_version_major() {
    local sv
    sv="$(grep -rh 'config\.script_version' "${UNREN_GAME}/script_version.rpy" "${UNREN_GAME}/script_version.txt" 2>/dev/null \
        | head -1 | sed -n 's/.*([[:space:]]*\([0-9][0-9]*\).*/\1/p')"
    [[ -n "$sv" ]] && printf '%s\n' "$sv" || printf '0\n'
}

_unren_decompile_auto_opts() {
    local -n _opts=$1
    local major py_major has_sl1=0 opt

    for opt in "${_opts[@]}"; do
        [[ "$opt" == "--sl1-as-python" ]] && has_sl1=1
    done

    if (( ! has_sl1 )); then
        major="$(_unren_script_version_major)"
        py_major="$(_unren_guess_python_major "$UNREN_APP" "$(_unren_renpy_platform)")"
        if [[ "$py_major" == "2" || "$major" -lt 7 ]]; then
            _opts+=(--sl1-as-python)
            echo "  Ren'Py ${major}/py${py_major}: enabling --sl1-as-python (screen language v1)" >&2
            echo >&2
        fi
    fi
}

unren_decompile() {
    local -a opts=()
    local unrpyc_py py_runner=() rc
    while [[ $# -gt 0 ]]; do
        opts+=("$1")
        shift
    done

    if ! find "$UNREN_GAME" -name '*.rpyc' -type f -print -quit 2>/dev/null | grep -q .; then
        echo "No .rpyc files found in ${UNREN_GAME}!"
        echo
        return 0
    fi

    _unren_decompile_auto_opts opts

    unrpyc_py="$(unren_resolve_unrpyc_python)"
    if [[ "$unrpyc_py" != "$UNREN_PYTHON" ]]; then
        py_runner=(env -u PYTHONHOME -u PYTHONPATH)
        echo "  Using ${unrpyc_py} for decompile (faster parallel unrpyc)"
        echo
    fi

    local errortemp
    errortemp="$(mktemp "${TMPDIR:-/tmp}/unren-rpyc.XXXXXX")"
    pushd "$UNREN_GAME" >/dev/null || return 0
    set +e
    "${py_runner[@]}" "$unrpyc_py" "$UNRPYC" "${opts[@]}" . >"$errortemp" 2>&1
    rc=$?
    set -e
    awk '!/^Co.*exec_prefix/ && !/^Traceback/ && !/^  File / && !/^ModuleNotFoundError/ && !/^The multiprocessing module/ && !/Attempting to deobfuscate/ && !/strategy extract_slot_/{ if (length) print "  > "$0 }' "$errortemp"
    if (( rc != 0 )); then
        echo
        echo "  Decompile finished with errors (exit ${rc})."
        awk '{ print "  ! "$0 }' "$errortemp" | tail -20
        echo
    elif grep -q "failed to decompile" "$errortemp" 2>/dev/null; then
        echo
        echo "  Decompile finished with some file failures (see summary above)."
        echo "  Pre-existing .rpy files are kept when a file fails under --clobber."
        echo
    fi
    rm -f "$errortemp"
    popd >/dev/null || return 0
    return 0
}
