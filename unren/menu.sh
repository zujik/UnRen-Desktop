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
    local -a pending=()
    local pending_count=0

    while true; do
        unren_menu_refresh_state
        mapfile -t pending < <(_unren_menu_patch_nums_pending)
        pending_count=${#pending[@]}

        echo " Available Options:"
        (( UNREN_MENU_HAS_ARCHIVES )) &&
            echo "   1) Extract RPA/JAS/RPC packages (in game folder)"
        (( UNREN_MENU_HAS_RPYC )) &&
            echo "   2) Decompile rpyc files (in game folder)"
        if (( UNREN_MENU_PATCH_DEV )); then
            echo "   3) Remove Console and Developer Menu"
        else
            echo "   3) Enable Console and Developer Menu"
        fi
        if (( UNREN_MENU_PATCH_QUICK )); then
            echo "   4) Remove Quick Save and Quick Load"
        else
            echo "   4) Enable Quick Save and Quick Load"
        fi
        if (( UNREN_MENU_PATCH_SKIP )); then
            echo "   5) Remove force-enable skipping"
        else
            echo "   5) Force enable skipping of unseen content"
        fi
        if (( UNREN_MENU_PATCH_ROLLBACK )); then
            echo "   6) Remove force-enable rollback"
        else
            echo "   6) Force enable rollback (scroll wheel)"
        fi
        if (( pending_count > 0 )); then
            echo "   7) Options $(_unren_menu_format_opt_list "${pending[@]}")"
        fi
        echo "   ${UNREN_MENU_OPT8_LABEL}"
        echo "   ${UNREN_MENU_OPT9_LABEL}"
        (( UNREN_MENU_HAS_RPYC )) &&
            echo "   0) Decompile rpyc (overwrite stub/missing .rpy only)"
        (( UNREN_MENU_HAS_MANGLED_RPYC )) &&
            echo "   c) Fix mangled RPYC signatures (rpycCorrector only)"
        if (( UNREN_MENU_PATCH_NSYNC )); then
            echo "   n) Remove Ren'Py cloud sync disable (unren-nsync.rpy)"
        else
            echo "   n) Disable Ren'Py cloud sync (unren-nsync.rpy)"
        fi
        (( UNREN_MENU_HAS_RESTORE )) &&
            echo "   r) Restore backup files (.rpa.org / .rpa.bak, ...)"
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
            0)
                (( UNREN_MENU_HAS_RPYC )) || { printf '\aInvalid choice.\n'; continue; }
                unren_decompile --clobber
                ;;
            g|G) unren_launch_game ;;
            1)
                (( UNREN_MENU_HAS_ARCHIVES )) || { printf '\aInvalid choice.\n'; continue; }
                unren_extract
                ;;
            2)
                (( UNREN_MENU_HAS_RPYC )) || { printf '\aInvalid choice.\n'; continue; }
                unren_decompile
                ;;
            3)
                if (( UNREN_MENU_PATCH_DEV )); then
                    unren_console_remove
                else
                    unren_console
                fi
                ;;
            4)
                if (( UNREN_MENU_PATCH_QUICK )); then
                    unren_quick_remove
                else
                    unren_quick
                fi
                ;;
            5)
                if (( UNREN_MENU_PATCH_SKIP )); then
                    unren_skip_remove
                else
                    unren_skip
                fi
                ;;
            6)
                if (( UNREN_MENU_PATCH_ROLLBACK )); then
                    unren_rollback_remove
                else
                    unren_rollback
                fi
                ;;
            7)
                (( pending_count > 0 )) || { printf '\aInvalid choice.\n'; continue; }
                _unren_menu_run_pending_patches
                ;;
            8) _unren_menu_run_combo_8 ;;
            9) _unren_menu_run_combo_9 ;;
            c|C)
                (( UNREN_MENU_HAS_MANGLED_RPYC )) || { printf '\aInvalid choice.\n'; continue; }
                unren_rpyc_correct
                ;;
            n|N)
                if (( UNREN_MENU_PATCH_NSYNC )); then
                    unren_sync_remove
                else
                    unren_sync_disable
                fi
                ;;
            r|R)
                (( UNREN_MENU_HAS_RESTORE )) || { printf '\aInvalid choice.\n'; continue; }
                unren_restore_org
                ;;
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
    echo " Linux and macOS - from UnRen.bat and UnRen-Ultrahack"
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
