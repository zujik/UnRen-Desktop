# Install Ren'Py patch scripts into the game folder

# BSD grep (macOS) has no --include; scan .rpy/.rpym only and stop at first hit.
_unren_game_script_grep() {
    local pattern="$1" use_ere="${2:-0}"
    local f

    while IFS= read -r -d '' f; do
        if [[ "$use_ere" == 1 ]]; then
            grep -qE "$pattern" "$f" 2>/dev/null && return 0
        else
            grep -Fq "$pattern" "$f" 2>/dev/null && return 0
        fi
    done < <(find "${UNREN_GAME}" \( -name '*.rpy' -o -name '*.rpym' \) -type f -print0 2>/dev/null)
    return 1
}

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
    if ! _unren_game_script_grep '^[[:space:]]*label[[:space:]]+Dev_Room([[:space:]:]|$)' 1 &&
        _unren_game_script_grep 'Dev_Room' 0; then
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
