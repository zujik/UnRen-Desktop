# Extract RPA archives with rpatool

unren_extract() {
    local f
    echo "  Searching for RPA packages in ${UNREN_GAME}"
    echo

    pushd "$UNREN_GAME" >/dev/null || return 1

    if ! compgen -G "*.rpa" >/dev/null; then
        echo "  No RPA packages found."
        popd >/dev/null || return 1
        return 0
    fi

    for f in *.rpa; do
        [[ -f "$f" ]] || continue
        echo "  Extracting ${f} ..."
        "$UNREN_PYTHON" ${PYARGS+"${PYARGS[@]}"} "$RPATOOL" -x -v "$f" 2>&1 | awk '!/^Co.*exec_prefix/{ if (length) print "  > "$0 }'
        if [[ -z "${UNREN_KEEP_RPA:-}" ]]; then
            mv -f "$f" "${f}.bak"
            echo "  Renamed ${f} -> ${f}.bak (Ren'Py will use extracted files only)"
        else
            echo "  Kept ${f} (set UNREN_KEEP_RPA to skip rename)"
        fi
    done

    popd >/dev/null || return 1
}
