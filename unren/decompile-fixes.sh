# Post-decompile repairs for known unrpyc gaps (generic + per-game hooks).

_unren_game_is_innocent_witches() {
    local f base
    for f in "${UNREN_APP}/Innocent Witches.exe" "${UNREN_APP}/Innocent_Witches.exe"; do
        [[ -f "$f" ]] && return 0
    done
    for f in "${UNREN_APP}"/*.exe; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f" .exe)"
        [[ "$base" == *Innocent*Witches* || "$base" == *innocent*witches* ]] && return 0
    done
    return 1
}

unren_decompile_fixes() {
    local -a roots=() root fix_py
    _unren_decompile_roots roots
    [[ ${#roots[@]} -gt 0 ]] || roots=("${UNREN_GAME}")

    fix_py="${UNREN_ROOT}/tools/decompile-fixes/fix-atl-tails.py"
    if [[ -f "$fix_py" ]]; then
        "${UNREN_PYTHON:-python3}" "$fix_py" "${roots[@]}" || true
    fi

    if _unren_game_is_innocent_witches; then
        # shellcheck source=patches/decompile-fixes/innocent-witches.sh
        source "${UNREN_ROOT}/patches/decompile-fixes/innocent-witches.sh"
        unren_decompile_fix_innocent_witches
    fi
}
