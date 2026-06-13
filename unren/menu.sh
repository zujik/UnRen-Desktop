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
        echo "   1) Extract RPA/JAS/RPC packages (in game folder)"
        echo "   2) Decompile rpyc files (in game folder)"
        echo "   3) Enable Console and Developer Menu"
        echo "   4) Enable Quick Save and Quick Load"
        echo "   5) Force enable skipping of unseen content"
        echo "   6) Force enable rollback (scroll wheel)"
        echo "   7) Options 3-6"
        echo "   8) Options 1-6 + install game launcher"
        echo "   9) Options 1-6 + rpycCorrector + deobfuscate + install launcher"
        echo "   0) Decompile rpyc (overwrite stub/missing .rpy only)"
        echo "   c) Fix mangled RPYC signatures (rpycCorrector only)"
        echo "   n) Disable Ren'Py cloud sync (unren-nsync.rpy)"
        echo "   r) Restore .org backup files (.rpa.org, .rpy.org, ...)"
        if is_osx; then
            echo "   m) Remove macOS quarantine (Gatekeeper) from game"
        fi
        echo "   g) Install / launch game (creates GameName.sh from .exe if needed)"
        echo "   q) Quit"
        echo
        read -r -s -n 1 -p "     Enter choice: " choice
        echo
        echo "----------------------------------------------------"
        echo

        case "$choice" in
            0) unren_decompile --clobber ;;
            g|G) unren_launch_game ;;
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
                echo
                echo " Installing game launcher ..."
                unren_install_launcher
                ;;
            9)
                unren_extract
                unren_decompile --try-harder
                unren_console
                unren_quick
                unren_skip
                unren_rollback
                echo
                echo " Installing game launcher ..."
                unren_install_launcher
                ;;
            c|C) unren_rpyc_correct ;;
            n|N) unren_sync_disable ;;
            r|R) unren_restore_org ;;
            m|M)
                if is_osx; then
                    unren_mac_quarantine
                else
                    printf '\aInvalid choice.\n'
                    continue
                fi
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
    local dir base
    raw="${raw%\'}"
    raw="${raw#\'}"
    if [[ -d "$raw" ]]; then
        (cd -P -- "$raw" && pwd)
    elif [[ -d "$(dirname -- "$raw")" ]]; then
        dir="$(cd -P -- "$(dirname -- "$raw")" && pwd)"
        base="$(basename -- "$raw")"
        echo "${dir}/${base}"
    else
        echo "$raw"
    fi
}

unren_main() {
    trap 'printf -- %s\\n "Interrupted."; exit 1' INT TERM

    cd "${UNREN_ROOT}" || exit 1
    unren_splash

    if [[ $# -ge 1 ]]; then
        UNREN_TARGET="$(unren_resolve_target_path "$1")"
        echo "Working with: ${UNREN_TARGET}"
    elif [[ -e "${UNREN_ROOT}/Contents/Resources/autorun/game" ]]; then
        UNREN_TARGET="${UNREN_ROOT}"
        echo "Working with (macOS bundle): ${UNREN_TARGET}"
    elif [[ -e "${UNREN_ROOT}/renpy" && -e "${UNREN_ROOT}/game" ]]; then
        UNREN_TARGET="${UNREN_ROOT}"
        echo "Working with (game root): ${UNREN_TARGET}"
    elif [[ -e "${UNREN_ROOT}/../renpy" && -e "${UNREN_ROOT}/../game" ]]; then
        UNREN_TARGET="$(cd "${UNREN_ROOT}/.." && pwd)"
        echo "Working with (parent of UnRen folder): ${UNREN_TARGET}"
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
