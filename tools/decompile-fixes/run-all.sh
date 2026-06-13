#!/bin/sh
# POSIX post-decompile fixes (safe to run from /bin/sh game launchers).

unren_run_decompile_fixes() {
    root="$1"
    game="${root}/game"

    [ -n "$root" ] && [ -d "$game" ] || return 0

    if [ -f "${root}/tools/decompile-fixes/fix-atl-tails.py" ]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON python3 \
            "${root}/tools/decompile-fixes/fix-atl-tails.py" "$game" || true
    fi
    if [ -f "${root}/tools/decompile-fixes/fix-sl-keywords.py" ]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON python3 \
            "${root}/tools/decompile-fixes/fix-sl-keywords.py" "$game" || true
    fi

    if [ ! -f "${root}/Innocent Witches.exe" ] && [ ! -f "${root}/Innocent_Witches.exe" ]; then
        return 0
    fi

    credits="${game}/credits/credits.rpy"
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

if [ "${0##*/}" = "run-all.sh" ]; then
    unren_run_decompile_fixes "${1:-.}"
fi
