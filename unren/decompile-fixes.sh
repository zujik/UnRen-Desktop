# Post-decompile repairs for known unrpyc gaps (bash entry; launcher uses tools/decompile-fixes/run-all.sh).

unren_decompile_fixes() {
    local -a roots=() root
    if declare -F _unren_decompile_roots >/dev/null 2>&1; then
        _unren_decompile_roots roots
    fi

    if [[ -f "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" ]]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON \
            sh "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" "${UNREN_ROOT}"
        return 0
    fi

    for root in "${roots[@]}"; do
        case "$root" in
            */game) app="${root%/game}" ;;
            *) app="${UNREN_ROOT}" ;;
        esac
        if [[ -f "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" ]]; then
            env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON \
                sh "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" "$app"
        fi
    done
}
