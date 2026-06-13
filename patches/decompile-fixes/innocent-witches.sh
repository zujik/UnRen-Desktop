# Innocent Witches — post-decompile repairs (Sad Crab custom Ren'Py statements).

unren_decompile_fix_innocent_witches() {
    local credits="${UNREN_GAME}/credits/credits.rpy"
    [[ -f "$credits" ]] || return 0

    # Truncated credits screen: styles decompile but exit_credits ends mid-imagebutton.
    if grep -q 'screen exit_credits' "$credits" && ! grep -q 'action ' "$credits"; then
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
