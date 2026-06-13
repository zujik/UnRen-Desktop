# Extract RPA / RPA-variant archives with rpatool

unren_extract() {
    local errortemp remove_flag=()
    echo "  Searching for RPA packages in ${UNREN_GAME}"
    echo
    read -r -s -n 1 -p "     Rename archives after extraction? (y/n): " rename_rpa
    echo
    if [[ "$rename_rpa" == "y" || "$rename_rpa" == "Y" ]]; then
        remove_flag=(-r)
    fi

    pushd "$UNREN_GAME" >/dev/null || return 1
    errortemp="$(mktemp "${TMPDIR:-/tmp}/unren-rpa.XXXXXX")"
    "$UNREN_PYTHON" ${PYARGS+"${PYARGS[@]}"} "$RPATOOL" ${remove_flag+"${remove_flag[@]}"} . 2>"$errortemp"
    awk '!/^Co.*exec_prefix/{ if (length) print "  > "$0 }' "$errortemp"
    rm -f "$errortemp"
    popd >/dev/null || return 1
}
