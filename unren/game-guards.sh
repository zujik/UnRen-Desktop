# Known-problem games: menu guards and early exits for extract/decompile.

UNREN_GUARD_IW_SLUG="innocent_witches"

_unren_is_innocent_witches_game() {
    local app="${1:-$UNREN_APP}"
    local base lower

    [[ -n "$app" ]] || return 1

    if [[ -f "${app}/Innocent Witches.exe" || -f "${app}/Innocent_Witches.exe" ]]; then
        return 0
    fi

    base="$(basename "$app")"
    lower="${base,,}"
    case "$lower" in
        *innocent*witch*) return 0 ;;
    esac

    if [[ -f "${app}/game/options.rpy" ]] &&
        grep -qE 'build\.name\s*=.*[Ii]nnocent.*[Ww]itch' "${app}/game/options.rpy" 2>/dev/null; then
        return 0
    fi

    if [[ -f "${app}/game/options.rpyc" ]] &&
        grep -aq 'Innocent Witches' "${app}/game/options.rpyc" 2>/dev/null; then
        return 0
    fi

    return 1
}

_unren_menu_guard_kind() {
    if _unren_is_innocent_witches_game "${1:-$UNREN_APP}"; then
        printf '%s\n' "$UNREN_GUARD_IW_SLUG"
        return 0
    fi
    return 1
}

_unren_guard_blocks_extract_decompile() {
    local kind="${1:-}"

    case "$kind" in
        innocent_witches)
            echo "  Innocent Witches — extract/decompile disabled (Sad Crab custom AST)."
            echo "  unrpyc cannot recover this game's scripts; full pipeline stays broken for years."
            echo "  Use fresh unzip → options 3–6 (or 7) → g. Do not use 1, 2, 0, 8, or 9."
            echo
            return 0
            ;;
    esac
    return 1
}

unren_guard_skip_extract() {
    local kind
    kind="$(_unren_menu_guard_kind)" || return 1
    _unren_guard_blocks_extract_decompile "$kind"
    return 0
}

unren_guard_skip_decompile() {
    unren_guard_skip_extract
}
