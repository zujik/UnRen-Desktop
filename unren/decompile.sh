# Decompile .rpyc files with unrpyc (Python 3)

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
    awk '!/^Co.*exec_prefix/ && !/^Traceback/ && !/^  File / && !/^ModuleNotFoundError/ && !/^The multiprocessing module/{ if (length) print "  > "$0 }' "$errortemp"
    if (( rc != 0 )); then
        echo
        echo "  Decompile failed (exit ${rc})."
        awk '{ print "  ! "$0 }' "$errortemp" | tail -20
        echo
    fi
    rm -f "$errortemp"
    popd >/dev/null || return 0
    return 0
}
