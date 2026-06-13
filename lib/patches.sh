# Install Ren'Py patch scripts into the game folder

_patch_install() {
    local name="$1"
    local dest="${UNREN_GAME}/${name}"
    cp "${PATCHES_DIR}/${name}" "$dest"
}

unren_console() {
    echo " Creating Developer/Console file..."
    _patch_install "unren-dev.rpy"
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
