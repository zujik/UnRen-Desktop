# rpycCorrector pre-pass (AON/SC4X v1.04, py3 port)

unren_rpyc_correct() {
    local py="${UNREN_PYTHON}" rc

    if [[ ! -f "${UNREN_APP}/renpy/script.py" ]]; then
        echo "  rpycCorrector: no renpy/script.py — skipping signature fix."
        echo
        return 0
    fi

    echo "  Running rpycCorrector (mangled RPYC signature / encoding fix)..."
    echo

    pushd "${UNREN_APP}" >/dev/null || return 1
    set +e
    "${py}" "${PYARGS[@]}" "${RPYCCORRECT}" 2>&1 | awk '{ if (length) print "  > "$0 }'
    rc=$?
    set -e
    popd >/dev/null || return 1

    if (( rc != 0 )); then
        echo
        echo "  rpycCorrector finished with exit ${rc} (may mean files were not altered)."
        echo
    fi
    return 0
}
