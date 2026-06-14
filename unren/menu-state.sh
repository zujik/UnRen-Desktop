# Probe game folder state and build dynamic menu labels.

UNREN_MENU_HAS_ARCHIVES=0
UNREN_MENU_HAS_RPYC=0
UNREN_MENU_HAS_RESTORE=0
UNREN_MENU_HAS_MANGLED_RPYC=0
UNREN_MENU_PATCH_DEV=0
UNREN_MENU_PATCH_QUICK=0
UNREN_MENU_PATCH_SKIP=0
UNREN_MENU_PATCH_ROLLBACK=0
UNREN_MENU_PATCH_NSYNC=0
UNREN_MENU_OPT8_LABEL=""
UNREN_MENU_OPT9_LABEL=""

_unren_menu_find_first() {
    find "${UNREN_GAME}" "$@" -print -quit 2>/dev/null | grep -q .
}

_unren_menu_has_archives() {
    local -a archives=()
    _unren_forall_collect_archives archives
    ((${#archives[@]} > 0))
}

_unren_menu_format_opt_list() {
    local -a nums=("$@")
    local -a ranges=()
    local start="" prev="" n

    for n in "${nums[@]}"; do
        [[ -n "$n" ]] || continue
        if [[ -z "$start" ]]; then
            start="$n"
            prev="$n"
            continue
        fi
        if (( n == prev + 1 )); then
            prev="$n"
            continue
        fi
        if [[ "$start" == "$prev" ]]; then
            ranges+=("$start")
        else
            ranges+=("${start}-${prev}")
        fi
        start="$n"
        prev="$n"
    done
    if [[ -n "$start" ]]; then
        if [[ "$start" == "$prev" ]]; then
            ranges+=("$start")
        else
            ranges+=("${start}-${prev}")
        fi
    fi

    if ((${#ranges[@]} == 0)); then
        printf ''
        return 0
    fi

    local IFS=
    local first=1 r
    for r in "${ranges[@]}"; do
        if (( first )); then
            printf '%s' "$r"
            first=0
        else
            printf ', %s' "$r"
        fi
    done
}

_unren_menu_patch_nums_pending() {
    local -a nums=()
    if (( ! UNREN_MENU_PATCH_DEV )); then nums+=(3); fi
    if (( ! UNREN_MENU_PATCH_QUICK )); then nums+=(4); fi
    if (( ! UNREN_MENU_PATCH_SKIP )); then nums+=(5); fi
    if (( ! UNREN_MENU_PATCH_ROLLBACK )); then nums+=(6); fi
    printf '%s\n' "${nums[@]}"
}

_unren_menu_workflow_nums() {
    local -a nums=()
    if (( UNREN_MENU_HAS_ARCHIVES )); then nums+=(1); fi
    if (( UNREN_MENU_HAS_RPYC )); then nums+=(2); fi
    printf '%s\n' "${nums[@]}"
}

_unren_menu_refresh_state() {
    local -a workflow=() pending=() combo=() label=""

    UNREN_MENU_HAS_ARCHIVES=0
    UNREN_MENU_HAS_RPYC=0
    UNREN_MENU_HAS_RESTORE=0
    UNREN_MENU_HAS_MANGLED_RPYC=0
    UNREN_MENU_PATCH_DEV=0
    UNREN_MENU_PATCH_QUICK=0
    UNREN_MENU_PATCH_SKIP=0
    UNREN_MENU_PATCH_ROLLBACK=0
    UNREN_MENU_PATCH_NSYNC=0
    UNREN_MENU_OPT8_LABEL="8) Install game launcher"
    UNREN_MENU_OPT9_LABEL="9) Deobfuscate + install launcher"

    _unren_menu_has_archives && UNREN_MENU_HAS_ARCHIVES=1
    _unren_menu_find_first \
        \( -name '*.rpyc' ! -path '*/sdk/*' ! -path '*/.sdk-sources-cache/*' \) \
        -type f && UNREN_MENU_HAS_RPYC=1
    _unren_menu_find_first \
        \( -name '*.rpa.org' -o -name '*.rpy.org' -o -name '*.rpyc.org' \
           -o -name '*.rpa.bak' -o -name '*.rpy.bak' -o -name '*.rpyc.bak' \) \
        -type f && UNREN_MENU_HAS_RESTORE=1
    _unren_has_mangled_rpyc && UNREN_MENU_HAS_MANGLED_RPYC=1

    [[ -f "${UNREN_GAME}/unren-dev.rpy" ]] && UNREN_MENU_PATCH_DEV=1
    [[ -f "${UNREN_GAME}/unren-quick.rpy" ]] && UNREN_MENU_PATCH_QUICK=1
    [[ -f "${UNREN_GAME}/unren-skip.rpy" ]] && UNREN_MENU_PATCH_SKIP=1
    [[ -f "${UNREN_GAME}/unren-rollback.rpy" ]] && UNREN_MENU_PATCH_ROLLBACK=1
    [[ -f "${UNREN_GAME}/unren-nsync.rpy" ]] && UNREN_MENU_PATCH_NSYNC=1

    mapfile -t workflow < <(_unren_menu_workflow_nums)
    mapfile -t pending < <(_unren_menu_patch_nums_pending)
    combo=()
    for n in "${workflow[@]}" "${pending[@]}"; do
        [[ -n "$n" ]] && combo+=("$n")
    done

    local opt9_extra="deobfuscate + install launcher"
    (( UNREN_MENU_HAS_MANGLED_RPYC )) && opt9_extra="rpycCorrector + ${opt9_extra}"

    if ((${#combo[@]} > 0)); then
        label="$(_unren_menu_format_opt_list "${combo[@]}")"
        UNREN_MENU_OPT8_LABEL="8) Options ${label} + install game launcher"
        UNREN_MENU_OPT9_LABEL="9) Options ${label} + ${opt9_extra}"
    else
        if (( UNREN_MENU_HAS_MANGLED_RPYC )); then
            UNREN_MENU_OPT9_LABEL="9) ${opt9_extra}"
        else
            UNREN_MENU_OPT9_LABEL="9) Deobfuscate + install launcher"
        fi
    fi
}

unren_menu_refresh_state() {
    _unren_menu_refresh_state "$@"
}

_unren_menu_run_extract_if() {
    if (( UNREN_MENU_HAS_ARCHIVES )); then
        unren_extract
    fi
}

_unren_menu_run_decompile_if() {
    local try_harder="${1:-}"
    (( UNREN_MENU_HAS_RPYC )) || return 0
    if [[ -n "$try_harder" ]]; then
        unren_decompile --try-harder
    else
        unren_decompile
    fi
}

_unren_menu_run_pending_patches() {
    if (( ! UNREN_MENU_PATCH_DEV )); then unren_console; fi
    if (( ! UNREN_MENU_PATCH_QUICK )); then unren_quick; fi
    if (( ! UNREN_MENU_PATCH_SKIP )); then unren_skip; fi
    if (( ! UNREN_MENU_PATCH_ROLLBACK )); then unren_rollback; fi
}

_unren_menu_run_combo_8() {
    unren_menu_refresh_state
    _unren_menu_run_extract_if
    _unren_menu_run_decompile_if
    _unren_menu_run_pending_patches
    echo
    echo " Installing game launcher ..."
    unren_install_launcher
}

_unren_menu_run_combo_9() {
    unren_menu_refresh_state
    if (( UNREN_MENU_HAS_MANGLED_RPYC )); then
        unren_rpyc_correct
    fi
    _unren_menu_run_extract_if
    _unren_menu_run_decompile_if try-harder
    _unren_menu_run_pending_patches
    echo
    echo " Installing game launcher ..."
    unren_install_launcher
}
