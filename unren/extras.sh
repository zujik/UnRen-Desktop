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
# Made by (SM) aka JoeLurmel @ f95zone.to - ported in UnRen-Desktop

init 9999 python:
    renpy.config.has_sync = False
    renpy.config.extra_savedirs = []
EOF
    echo "  + Wrote ${patch}"
    echo
}

unren_restore_org() {
    local found=0 restored=0
    local backup dstfile filename dstfilename dir prev_dir="" suffix=""

    echo "  Restoring backup files in game/ (.org and .bak from UnRen)"
    echo

    while IFS= read -r -d '' backup; do
        found=1
        dir="$(dirname "$backup")"
        if [[ "$dir" != "$prev_dir" ]]; then
            echo "  ${dir}/"
            prev_dir="$dir"
        fi
        filename="$(basename "$backup")"
        case "$filename" in
            *.rpa.org|*.rpy.org|*.rpyc.org)
                suffix=".org"
                ;;
            *.rpa.bak|*.rpy.bak|*.rpyc.bak)
                suffix=".bak"
                ;;
            *)
                continue
                ;;
        esac
        dstfilename="${filename%${suffix}}"
        dstfile="${backup%${suffix}}"
        if mv -f "$backup" "$dstfile" 2>/dev/null; then
            echo "    ${filename} -> ${dstfilename}"
            ((restored++)) || true
        else
            echo "    ! failed: ${filename}"
        fi
    done < <(find "${UNREN_GAME}" \( \
        -name '*.rpa.org' -o -name '*.rpy.org' -o -name '*.rpyc.org' \
        -o -name '*.rpa.bak' -o -name '*.rpy.bak' -o -name '*.rpyc.bak' \
        \) -type f -print0 2>/dev/null)

    if (( ! found )); then
        echo "  No .org or .bak backup files found."
        echo "  (.org = pre-patch copies; .bak = archives renamed by option 1 extract)"
    else
        echo
        echo "  Restored ${restored} file(s)."
    fi
    echo
}
