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
}

if [ "${0##*/}" = "run-all.sh" ]; then
    unren_run_decompile_fixes "${1:-.}"
fi
