# RPC3 bytecode: unreliable decompile, launch from matching .rpyc

UNREN_RPC3_QUARANTINE_SUFFIX=".unren-rpc3"

_unren_rpc3_is_patch_source() {
    case "${1##*/}" in
        unren-*.rpy|unren-*.rpym) return 0 ;;
    esac
    return 1
}

_unren_rpc3_compiled_sibling() {
    local source="$1"
    case "$source" in
        *.rpy) printf '%s\n' "${source%.rpy}.rpyc" ;;
        *.rpym) printf '%s\n' "${source%.rpym}.rpymc" ;;
        *) return 1 ;;
    esac
}

_unren_rpc3_collect_stale_sources() {
    local -a roots=() out=()
    local root source compiled

    _unren_decompile_roots roots
    for root in "${roots[@]}"; do
        while IFS= read -r -d '' source; do
            _unren_rpc3_is_patch_source "$source" && continue
            compiled="$(_unren_rpc3_compiled_sibling "$source")" || continue
            [[ -f "$compiled" ]] || continue
            out+=("$source")
        done < <(find "$root" \( -name '*.rpy' -o -name '*.rpym' \) -type f -print0 2>/dev/null)
    done

    ((${#out[@]} > 0)) && printf '%s\0' "${out[@]}"
}

_unren_rpc3_stale_source_count() {
    local -a stale=()
    while IFS= read -r -d '' _; do
        stale+=("x")
    done < <(_unren_rpc3_collect_stale_sources)
    printf '%s\n' "${#stale[@]}"
}

unren_rpc3_quarantine_sources() {
    local -a stale=()
    local source name removed=0 keep=0 verbose=0

    _unren_has_rpc3_rpyc || return 0

    while IFS= read -r -d '' source; do
        stale+=("$source")
    done < <(_unren_rpc3_collect_stale_sources)

    ((${#stale[@]} == 0)) && return 0

    [[ "${UNREN_RPC3_KEEP_QUARANTINED:-}" == 1 ]] && keep=1
    [[ "${UNREN_VERBOSE:-}" == 1 ]] && verbose=1

    for source in "${stale[@]}"; do
        name="${source#"${UNREN_APP}/game/"}"
        [[ "$name" == "$source" ]] && name="${source##*/}"
        if (( keep )); then
            [[ -f "${source}${UNREN_RPC3_QUARANTINE_SUFFIX}" ]] && continue
            if mv -f "$source" "${source}${UNREN_RPC3_QUARANTINE_SUFFIX}" 2>/dev/null; then
                (( verbose )) && echo "    ${name} -> ${name}${UNREN_RPC3_QUARANTINE_SUFFIX}"
                (( removed++ )) || true
            fi
        elif rm -f "$source" 2>/dev/null; then
            (( verbose )) && echo "    removed ${name}"
            (( removed++ )) || true
        fi
    done

    if (( removed > 0 )); then
        if (( keep )); then
            echo "  RPC3: sidelined ${removed} unreliable decompiled source file(s) — launching from .rpyc."
            echo "  (Kept as *${UNREN_RPC3_QUARANTINE_SUFFIX}; unset UNREN_RPC3_KEEP_QUARANTINED to delete instead.)"
        else
            echo "  RPC3: removed ${removed} unreliable decompiled .rpy — launching from matching .rpyc."
        fi
        echo
    fi
    return 0
}

unren_rpc3_restore_sources() {
    local -a roots=()
    local root backup dst restored=0
    local name

    _unren_has_rpc3_rpyc && {
        echo "  RPC3 game — not restoring *${UNREN_RPC3_QUARANTINE_SUFFIX} sources (unreliable decompiles)."
        echo "  Launch with g from .rpyc. Delete *${UNREN_RPC3_QUARANTINE_SUFFIX} manually if you want them gone."
        echo
        return 0
    }

    _unren_decompile_roots roots
    for root in "${roots[@]}"; do
        while IFS= read -r -d '' backup; do
            dst="${backup%${UNREN_RPC3_QUARANTINE_SUFFIX}}"
            [[ -n "$dst" && "$dst" != "$backup" ]] || continue
            if mv -f "$backup" "$dst" 2>/dev/null; then
                name="${backup#"${root}/"}"
                echo "    ${name} -> ${name%${UNREN_RPC3_QUARANTINE_SUFFIX}}"
                (( restored++ )) || true
            fi
        done < <(find "$root" \( -name "*${UNREN_RPC3_QUARANTINE_SUFFIX}" \) -type f -print0 2>/dev/null)
    done

    if (( restored > 0 )); then
        echo "  Restored ${restored} RPC3-quarantined source file(s)."
        echo
    fi
    return 0
}

unren_rpc3_purge_quarantined() {
    local -a roots=()
    local root backup removed=0 name

    _unren_has_rpc3_rpyc || return 0

    _unren_decompile_roots roots
    for root in "${roots[@]}"; do
        while IFS= read -r -d '' backup; do
            name="${backup#"${root}/"}"
            if rm -f "$backup" 2>/dev/null; then
                (( UNREN_VERBOSE )) && echo "    removed ${name}"
                (( removed++ )) || true
            fi
        done < <(find "$root" \( -name "*${UNREN_RPC3_QUARANTINE_SUFFIX}" \) -type f -print0 2>/dev/null)
    done

    if (( removed > 0 )); then
        echo "  RPC3: deleted ${removed} leftover *${UNREN_RPC3_QUARANTINE_SUFFIX} file(s)."
        echo
    fi
    return 0
}
