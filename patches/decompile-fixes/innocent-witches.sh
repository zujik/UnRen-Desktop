# Innocent Witches — post-decompile repairs (Sad Crab custom Ren'Py statements).

unren_decompile_fix_innocent_witches() {
    local root="${UNREN_ROOT:-.}"
    local game="${UNREN_GAME:-${root}/game}"
    local tools="${root}/tools/decompile-fixes"
    local py="env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON python3"

    [ -d "$game" ] || return 0

    for script in fix-sonya-store.py fix-achievements-init.py fix-spell-cast-anims.py fix-community-tl.py fix-tutorial-settings.py; do
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
