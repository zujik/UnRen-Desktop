# Innocent Witches — post-decompile repairs (Sad Crab custom Ren'Py statements).
#
# WARNING: full decompile is not launch-viable. ~90k+ COULD NOT DECOMPILE markers,
# truncated menus/loadsave.rpy, missing scripts/loadsave.rpy, custom DynamicStatement
# / RawMenu / LayeredImageStatement AST throughout plot and locations.
#
# Vanilla play (no extract/decompile): use options 3–6 + g only — this hook is skipped.

_unren_iw_needs_decompile_fixes() {
    local game="$1"
    # Force for experiments / re-apply after decompile (option 2/8/9).
    if [ -n "${UNREN_IW_FIXES:-}" ]; then
        return 0
    fi
    # Existing UnRen stubs from a prior decompile session.
    if [ -f "${game}/menus/main_menu_stub.rpy" ] \
        || [ -f "${game}/mechanics/tutorial/init_stub.rpy" ] \
        || [ -f "${game}/menus/splashscreen.rpy" ] && [ -f "${game}/menus/splashscreen.rpyc" ]; then
        case "$(head -n 1 "${game}/menus/splashscreen.rpy" 2>/dev/null)" in
            *"UnRen stub"*) return 0 ;;
        esac
    fi
    # Decompiled sources with unrpyc failure markers.
    if find "$game" -name '*.rpy' -print0 2>/dev/null \
        | xargs -0 grep -l 'COULD NOT DECOMPILE' 2>/dev/null \
        | head -1 | grep -q .; then
        return 0
    fi
    return 1
}

unren_decompile_fix_innocent_witches() {
    local root="${UNREN_ROOT:-.}"
    local game="${UNREN_GAME:-${root}/game}"
    local tools="${root}/tools/decompile-fixes"
    local py="env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON python3"

    [ -d "$game" ] || return 0

    if ! _unren_iw_needs_decompile_fixes "$game"; then
        return 0
    fi

    for script in fix-sonya-store.py fix-achievements-init.py fix-spell-cast-anims.py fix-community-tl.py fix-tutorial-settings.py fix-memories-scopes.py fix-live2d-tails.py fix-layered-images.py fix-missing-menus.py fix-iw-runtime-stubs.py fix-main-menu.py fix-assistant-actions.py fix-game-menu.py fix-characters.py; do
        if [ -f "${tools}/${script}" ]; then
            $py "${tools}/${script}" "$game" || true
        fi
    done

    local credits="${game}/credits/credits.rpy"
    if [ -f "$credits" ] && grep -q 'screen exit_credits' "$credits" && ! grep -q 'action ' "$credits"; then
        head -n 69 "$credits" > "${credits}.unren-fix"
        cat >> "${credits}.unren-fix" <<'EOF'

screen exit_credits():
    zorder 6
    textbutton "Back" align (0.98, 0.02):
        action Return()
EOF
        mv "${credits}.unren-fix" "$credits"
        echo "  + Repaired truncated game/credits/credits.rpy (exit_credits stub)"
    fi
}
