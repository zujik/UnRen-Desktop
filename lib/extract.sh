# Extract RPA archives with rpatool

unren_extract() {
    local rename_rpa f
    echo "  Searching for RPA packages in ${UNREN_GAME}"
    echo
    read -r -s -n 1 -p "     Rename archives after extraction? (y/n): " rename_rpa
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
        if [[ "$rename_rpa" == "y" || "$rename_rpa" == "Y" ]]; then
            mv -f "$f" "${f}.bak"
            echo "  Renamed ${f} -> ${f}.bak"
        fi
    done

    popd >/dev/null || return 1
}
