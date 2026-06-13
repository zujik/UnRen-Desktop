# Decompile .rpyc files with unrpyc (Python 3)

unren_decompile() {
    local -a opts=(--init-offset)
    while [[ $# -gt 0 ]]; do
        opts+=("$1")
        shift
    done

    if ! find "$UNREN_GAME" -name '*.rpyc' -type f -print -quit 2>/dev/null | grep -q .; then
        echo "No .rpyc files found in ${UNREN_GAME}!"
        echo
        return 1
    fi

    local errortemp
    errortemp="$(mktemp "${TMPDIR:-/tmp}/unren-rpyc.XXXXXX")"
    pushd "$UNREN_GAME" >/dev/null || return 1
    "$UNREN_PYTHON" ${PYARGS+"${PYARGS[@]}"} "$UNRPYC" "${opts[@]}" . 2>"$errortemp"
    awk '!/^Co.*exec_prefix/{ if (length) print "  > "$0 }' "$errortemp"
    rm -f "$errortemp"
    popd >/dev/null || return 1
}
