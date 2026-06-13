# Post-decompile repairs (POSIX — safe when sourced from /bin/sh launchers or bash UnRen).

unren_decompile_fixes() {
    root="${UNREN_ROOT:-${UNREN_APP:-.}}"
    if [ -f "${root}/tools/decompile-fixes/run-all.sh" ]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON \
            sh "${root}/tools/decompile-fixes/run-all.sh" "$root"
    fi
}
