# Install Ren'Py patch scripts into the game folder

_patch_install() {
    local name="$1"
    local dest="${UNREN_GAME}/${name}"
    cp "${PATCHES_DIR}/${name}" "$dest"
}

_patch_remove() {
    local name="$1"
    local dest="${UNREN_GAME}/${name}"
    [[ -f "$dest" ]] || return 0
    rm -f "$dest"
    echo "  - Removed ${name}"
}

unren_console_remove() {
    echo " Removing Developer/Console patch..."
    _patch_remove "unren-dev.rpy"
    _patch_remove "unren-dev-compat.rpy"
    echo
}

unren_quick_remove() {
    echo " Removing Quick Save/Quick Load patch..."
    _patch_remove "unren-quick.rpy"
    echo
}

unren_skip_remove() {
    echo " Removing skip patch..."
    _patch_remove "unren-skip.rpy"
    echo
}

unren_rollback_remove() {
    echo " Removing rollback patch..."
    _patch_remove "unren-rollback.rpy"
    echo
}

unren_sync_remove() {
    echo " Removing cloud sync disable patch..."
    _patch_remove "unren-nsync.rpy"
    echo
}

unren_console() {
    echo " Creating Developer/Console file..."
    _patch_install "unren-dev.rpy"
    if ! grep -rqE '^[[:space:]]*label[[:space:]]+Dev_Room([[:space:]:]|$)' "${UNREN_GAME}" 2>/dev/null &&
        grep -rq 'Dev_Room' "${UNREN_GAME}" 2>/dev/null; then
        _patch_install "unren-dev-compat.rpy"
        echo "  + Dev_Room stub (release build omits dev label)"
    fi
    echo "  + Console: SHIFT+O"
    echo "  + Dev Menu: SHIFT+D"
    echo
}

unren_quick() {
    echo " Creating Quick Save/Quick Load file..."
    {
        printf 'init 999 python:\n'
        printf '    try:\n'
        printf "        config.underlay[0].keymap['quickSave'] = QuickSave()\n"
        printf "        config.keymap['quickSave'] = '%s'\n" "$QUICK_SAVE_KEY"
        printf "        config.underlay[0].keymap['quickLoad'] = QuickLoad()\n"
        printf "        config.keymap['quickLoad'] = '%s'\n" "$QUICK_LOAD_KEY"
        printf '    except:\n'
        printf '        pass\n'
    } > "${UNREN_GAME}/unren-quick.rpy"
    echo "  + Quick Save: ${QUICK_SAVE_KEY#K_}"
    echo "  + Quick Load: ${QUICK_LOAD_KEY#K_}"
    echo
}

unren_skip() {
    echo " Creating skip file..."
    _patch_install "unren-skip.rpy"
    echo "  + You can now skip all text using TAB and CTRL keys"
    echo
}

unren_rollback() {
    echo " Creating rollback file..."
    _patch_install "unren-rollback.rpy"
    echo "  + You can now rollback using the scrollwheel"
    echo
}
