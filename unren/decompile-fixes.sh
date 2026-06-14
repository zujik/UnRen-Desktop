# Post-decompile repairs (POSIX — safe when sourced from /bin/sh launchers or bash UnRen).

unren_decompile_fixes() {
    root="${UNREN_ROOT:-${UNREN_APP:-.}}"
    game="${root}/game"

    [ -n "$root" ] && [ -d "$game" ] || return 0

    if [ -f "${root}/tools/decompile-fixes/run-all.sh" ]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON \
            sh "${root}/tools/decompile-fixes/run-all.sh" "$root"
    fi

    if [ -d "${root}/patches/decompile-fixes" ]; then
        for patch in "${root}/patches/decompile-fixes"/*.sh; do
            [ -f "$patch" ] || continue
            # shellcheck source=/dev/null
            . "$patch"
        done
    fi

    if [ -f "${root}/Innocent Witches.exe" ] || [ -f "${root}/Innocent_Witches.exe" ] ||
        { type _unren_is_innocent_witches_game >/dev/null 2>&1 && _unren_is_innocent_witches_game "$root"; }; then
        if type unren_decompile_fix_innocent_witches >/dev/null 2>&1; then
            UNREN_ROOT="$root" UNREN_GAME="$game" unren_decompile_fix_innocent_witches
        fi
    fi
}
