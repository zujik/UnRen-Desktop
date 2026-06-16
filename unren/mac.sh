# macOS helpers (optional — not run by default)

_unren_mac_auto_quarantine_clear() {
    local target="${1:-}"
    [[ -n "$target" && -e "$target" ]] || return 0
    is_osx || return 0
    xattr -rd com.apple.quarantine "$target" 2>/dev/null || true
}

unren_mac_quarantine() {
    if ! is_osx; then
        echo "  macOS quarantine removal is only available on Darwin."
        echo
        return 0
    fi

    local target="${UNREN_TARGET}"
    if [[ -e "${UNREN_TARGET}/Contents/Resources/autorun/game" ]]; then
        target="${UNREN_TARGET}"
    fi

    echo "  Removing com.apple.quarantine from:"
    echo "    ${target}"
    echo "  (Gatekeeper may have blocked the game's embedded Python.)"
    echo

    if xattr -rd com.apple.quarantine "${target}" 2>/dev/null; then
        echo "  Quarantine attributes cleared."
    else
        echo "  No quarantine attributes found (or xattr failed)."
    fi
    echo
}
