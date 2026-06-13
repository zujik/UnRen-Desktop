# Launch a Ren'Py game using bundled or game SDK launchers (Feature 2 — stub)

unren_launch_game() {
    local launcher
    if [[ -x "${UNREN_APP}/renpy.sh" ]]; then
        launcher="${UNREN_APP}/renpy.sh"
    elif [[ -n "$UNREN_SDK_ROOT" ]]; then
        launcher="$(sdk_renpy_launcher "$UNREN_SDK_ROOT")"
    else
        launcher="$(sdk_renpy_launcher "$SDK_PY3_DIR")"
    fi

    if [[ -z "$launcher" || ! -e "$launcher" ]]; then
        echo "No renpy.sh / renpy.py launcher found. Copy SDK launchers with scripts/populate-sdk.sh"
        return 1
    fi

    echo "Launching game via ${launcher} ..."
    (cd "$UNREN_APP" && exec "$launcher" "$UNREN_GAME")
}
