# Extra patches from UnRen-forall (Windows): sync cleanup, .org restore

unren_sync_disable() {
    local patch="${UNREN_GAME}/unren-nsync.rpy"
    echo "  Disabling Ren'Py cloud sync (AppData / ~/.renpy sync folders)..."
    if [[ -f "$patch" ]]; then
        echo "  + ${patch} already exists — skipping"
        echo
        return 0
    fi
    cat > "$patch" <<'EOF'
# Made by (SM) aka JoeLurmel @ f95zone.to — ported in UnRen-Desktop

init 9999 python:
    renpy.config.has_sync = False
    renpy.config.extra_savedirs = []
EOF
    echo "  + Wrote ${patch}"
    echo
}

unren_restore_org() {
    local found=0 restored=0
    local orgfile dstfile filename dstfilename dir prev_dir=""

    echo "  Restoring *.rpa.org / *.rpy.org / *.rpyc.org backups in game/"
    echo

    while IFS= read -r -d '' orgfile; do
        found=1
        dir="$(dirname "$orgfile")"
        if [[ "$dir" != "$prev_dir" ]]; then
            echo "  ${dir}/"
            prev_dir="$dir"
        fi
        filename="$(basename "$orgfile")"
        dstfilename="${filename%.org}"
        dstfile="${orgfile%.org}"
        if mv -f "$orgfile" "$dstfile" 2>/dev/null; then
            echo "    ${filename} -> ${dstfilename}"
            ((restored++)) || true
        else
            echo "    ! failed: ${filename}"
        fi
    done < <(find "${UNREN_GAME}" \( -name '*.rpa.org' -o -name '*.rpy.org' -o -name '*.rpyc.org' \) -type f -print0 2>/dev/null)

    if (( ! found )); then
        echo "  No .org backup files found."
    else
        echo
        echo "  Restored ${restored} file(s)."
    fi
    echo
}
