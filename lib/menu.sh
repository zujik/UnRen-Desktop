# Main menu and orchestration

unren_finished() {
    local rorq=
    echo "----------------------------------------------------"
    echo
    echo "  Finished!"
    echo
    read -r -s -n 1 -p '     Press "1" for menu, any other key to exit: ' rorq
    echo
    if [[ "$rorq" == "1" ]]; then
        unren_menu
    else
        clear
        exit 0
    fi
}

unren_menu() {
    local choice=
    while true; do
        echo " Available Options:"
        echo "   1) Extract RPA packages (in game folder)"
        echo "   2) Decompile rpyc files (in game folder)"
        echo "   3) Enable Console and Developer Menu"
        echo "   4) Enable Quick Save and Quick Load"
        echo "   5) Force enable skipping of unseen content"
        echo "   6) Force enable rollback (scroll wheel)"
        echo "   7) Options 3-6"
        echo "   8) Options 1-6"
        echo "   9) Options 1-6 + Deobfuscate rpyc"
        echo "   0) Decompile rpyc and overwrite existing rpy files"
        echo "   q) Quit"
        echo
        read -r -s -n 1 -p "     Enter choice (0-9, q): " choice
        echo
        echo "----------------------------------------------------"
        echo

        case "$choice" in
            0) unren_decompile --clobber ;;
            1) unren_extract ;;
            2) unren_decompile ;;
            3) unren_console ;;
            4) unren_quick ;;
            5) unren_skip ;;
            6) unren_rollback ;;
            7)
                unren_console
                unren_quick
                unren_skip
                unren_rollback
                ;;
            8)
                unren_extract
                unren_decompile
                unren_console
                unren_quick
                unren_skip
                unren_rollback
                ;;
            9)
                unren_extract
                unren_decompile --try-harder
                unren_console
                unren_quick
                unren_skip
                unren_rollback
                ;;
            q|Q)
                echo "Bye..."
                exit 0
                ;;
            *)
                printf '\aInvalid choice.\n'
                continue
                ;;
        esac
        unren_finished
    done
}

unren_splash() {
    clear
    echo
    echo "   __  __      ____                    __   "
    echo "  / / / /___  / __ \___  ____    _____/ /_  "
    echo " / / / / __ \/ /_/ / _ \/ __ \  / ___/ __ \ "
    echo "/ /_/ / / / / _, _/  __/ / / / (__  ) / / / "
    echo "\____/_/ /_/_/ |_|\___/_/ /_(_)____/_/ /_/  "
    echo " UnRen-Desktop v${UNREN_VERSION} ${UNREN_VERSION_DATE}"
    echo " Linux and macOS — from UnRen.bat and UnRen-Ultrahack"
    echo " https://github.com/zujik/UnRen-Desktop"
    echo
    echo "----------------------------------------------------"
    echo
}

unren_resolve_target_path() {
    local raw="$1"
    raw="${raw%\'}"
    raw="${raw#\'}"
    if [[ -d "$raw" ]]; then
        (cd -P -- "$raw" && pwd)
    elif [[ -d "$(dirname -- "$raw")" ]]; then
        (cd -P -- "$(dirname -- "$raw")" && pwd)/$(basename -- "$raw")
    else
        echo "$raw"
    fi
}

unren_main() {
    trap 'printf -- %s\\n "Interrupted."; exit 1' INT TERM

    unren_splash

    if [[ $# -ge 1 ]]; then
        UNREN_TARGET="$(unren_resolve_target_path "$1")"
        echo "Working with: ${UNREN_TARGET}"
    else
        echo "Drag-and-drop the game folder or .app here, then press ENTER:"
        read -r input_path
        UNREN_TARGET="$(unren_resolve_target_path "$input_path")"
    fi
    echo

    resolve_game_and_python
    echo "Game folder: ${UNREN_GAME}"
    echo "Python:      ${UNREN_PYTHON}"
    echo

    unren_menu
}
