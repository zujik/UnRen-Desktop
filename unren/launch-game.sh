# Install and launch Ren'Py games on Linux/macOS (lib/ first, sdk/ fallback)

_unren_detect_game_basename() {
    local app="$1" f base

    for f in "$app"/*.exe; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f" .exe)"
        case "$base" in
            renpy|renpy.exe|python|pythonw) continue ;;
        esac
        printf '%s\n' "$base"
        return 0
    done

    for f in "$app"/*.sh; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f" .sh)"
        case "$base" in
            UnRen|renpy|renpy3|renpy2) continue ;;
        esac
        printf '%s\n' "$base"
        return 0
    done

    for f in "$app"/*.py; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f" .py)"
        case "$base" in
            renpy|renpy3|renpy2) continue ;;
        esac
        printf '%s\n' "$base"
        return 0
    done

    if [[ -f "${UNREN_GAME}/options.rpy" ]]; then
        base="$(grep -m1 'define build\.name' "${UNREN_GAME}/options.rpy" 2>/dev/null \
            | sed -n 's/.*"\([^"]*\)".*/\1/p')"
        if [[ -n "$base" ]]; then
            printf '%s\n' "$base"
            return 0
        fi
    fi

    printf '%s\n' "$(basename "$app")"
}

_unren_launch_lib_dir() {
    local app="$1" py_major="$2" platform="$3"
    local game_lib sdk_root sdk_lib

    game_lib="${app}/lib/py${py_major}-${platform}"
    if [[ -d "$game_lib" ]]; then
        chmod -f +x "${game_lib}/python" "${game_lib}/renpy" "${game_lib}/"* 2>/dev/null || true
    fi
    if [[ -d "$game_lib" ]] && {
        [[ -x "${game_lib}/renpy" || -x "${game_lib}/python" ]]
    }; then
        printf '%s\n' "$game_lib"
        return 0
    fi

    if _unren_resolve_sdk_runtime "$app" "$py_major" "$platform" sdk_root sdk_lib; then
        printf '%s\n' "$sdk_lib"
        return 0
    fi

    return 1
}

_unren_launcher_sdk_elif_block() {
    local app="$1" py_major="$2" platform="$3"
    local slice sdk_root lib_dir rel_lib phome py_args layout ld_line

    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        sdk_root="$(_unren_sdk_slice_dir "$slice")"
        lib_dir="$(_unren_sdk_lib_dir "$sdk_root" "$py_major" "$platform")" || continue
        _unren_sdk_lib_usable "$lib_dir" || continue

        rel_lib="${lib_dir#"${app}/"}"
        phome="$(_unren_sdk_pythonhome "$sdk_root" "$lib_dir")"
        py_args="$(_unren_sdk_py_args "$sdk_root")"
        layout="$(_unren_sdk_layout "$sdk_root")"
        rel_sdk="${sdk_root#"${app}/"}"
        case "$layout" in
            renpy6|renpy5)
                ld_line='    SDK_LD_PATH="$LIB:$LIB/lib"'
                renpy_py_line="    SDK_RENPY_PY=\"\$ROOT/${rel_sdk}/renpy.py\""
                ;;
        *)
            ld_line='    SDK_LD_PATH="$LIB"'
            renpy_py_line="    SDK_RENPY_PY=\"\$ROOT/${rel_sdk}/renpy.py\""
            ;;
        esac

        printf '%s\n' \
            "elif [ -d \"\$ROOT/${rel_lib}\" ] && { [ -x \"\$ROOT/${rel_lib}/renpy\" ] || [ -x \"\$ROOT/${rel_lib}/python\" ] || [ -x \"\$ROOT/${rel_lib}/python.real\" ]; }; then" \
            "    LIB=\"\$ROOT/${rel_lib}\"" \
            "    SDK_PYHOME=\"\$ROOT/${phome#"${app}/"}\"" \
            "    SDK_PY_ARGS=\"${py_args}\"" \
            "$ld_line" \
            "$renpy_py_line"
    done < <(_unren_sdk_fallback_chain "$app")
}

# Legacy py2 pygame_sdl2 has no native Wayland — use XWayland on Wayland sessions.
# py3 runtimes (native lib/ or sdk/py3-*) leave SDL unset; modern SDL2 picks
# Wayland or X11 from the session and can fall back if Wayland init fails.
_unren_runtime_needs_xwayland() {
    local py_major="$1" lib_dir="$2"
    [[ "$py_major" == 2 ]]
}

_unren_configure_sdl_video() {
    local py_major="$1" lib_dir="$2"

    if [[ -n "${UNREN_SDL_VIDEODRIVER:-}" ]]; then
        export SDL_VIDEODRIVER="$UNREN_SDL_VIDEODRIVER"
        return 0
    fi
    if ! is_linux || ! _unren_runtime_needs_xwayland "$py_major" "$lib_dir"; then
        return 0
    fi
    # KDE and others often export SDL_VIDEODRIVER=wayland; py2 SDL cannot use it.
    if [[ -z "${SDL_VIDEODRIVER:-}" || "${SDL_VIDEODRIVER}" == "wayland" ]]; then
        export SDL_VIDEODRIVER=x11
    fi
}

_unren_launcher_sdl_block() {
    local sdl_legacy="$1"
    if [[ "$sdl_legacy" == 1 ]]; then
        cat <<'SDL'
# py2 on Linux: bundled pygame_sdl2 has no Wayland backend (use XWayland via x11).
# KDE often sets SDL_VIDEODRIVER=wayland globally — override that for py2.
case "$(uname -s)" in
    Linux)
        if [ -n "$UNREN_SDL_VIDEODRIVER" ]; then
            export SDL_VIDEODRIVER="$UNREN_SDL_VIDEODRIVER"
        elif [ -z "$SDL_VIDEODRIVER" ] || [ "$SDL_VIDEODRIVER" = "wayland" ]; then
            export SDL_VIDEODRIVER=x11
        fi
        ;;
esac

SDL
    fi
}

_unren_render_launcher_sh() {
    local dest="$1" py_major="$2" sdk_elifs="$3" sdl_block="$4"
    local tmp_elifs tmp_sdl

    if [[ ! -f "$LAUNCHER_SH_TEMPLATE" ]]; then
        unren_die "Launcher template missing: ${LAUNCHER_SH_TEMPLATE}"
    fi

    tmp_elifs="$(mktemp)"
    tmp_sdl="$(mktemp)"
    printf '%s' "$sdk_elifs" >"$tmp_elifs"
    printf '%s' "$sdl_block" >"$tmp_sdl"

    env -u PYTHONHOME -u PYTHONPATH python3 - "$LAUNCHER_SH_TEMPLATE" "$dest" "$py_major" "$tmp_elifs" "$tmp_sdl" <<'PY'
import pathlib
import sys

template_path, dest, py_major, elifs_path, sdl_path = sys.argv[1:6]
content = pathlib.Path(template_path).read_text()
content = content.replace("@@UNREN_PY_MAJOR@@", py_major)
content = content.replace("@@UNREN_SDK_ELIFS@@", pathlib.Path(elifs_path).read_text())
content = content.replace("@@UNREN_SDL_BLOCK@@", pathlib.Path(sdl_path).read_text())
pathlib.Path(dest).write_text(content)
PY

    rm -f "$tmp_elifs" "$tmp_sdl"
}

_unren_install_launcher_py() {
    local dest="$1" py_major="$2" platform="$3"
    local sdk_root lib_dir src

    if [[ -f "${UNREN_APP}/renpy.py" ]]; then
        src="${UNREN_APP}/renpy.py"
    elif _unren_resolve_sdk_runtime "$UNREN_APP" "$py_major" "$platform" sdk_root lib_dir &&
         [[ -f "${sdk_root}/renpy.py" ]]; then
        src="${sdk_root}/renpy.py"
    else
        echo "  Warning: could not create $(basename "$dest") (renpy.py template missing)"
        return 0
    fi

    if [[ -f "$LAUNCHER_PY_HEADER" ]]; then
        cat "$LAUNCHER_PY_HEADER" "$src" >"$dest"
    else
        cp -a "$src" "$dest"
    fi
    chmod +x "$dest" 2>/dev/null || true
}

unren_install_launcher() {
    local basename="${1-}" sh_path py_path sdk_elifs sdl_block sdl_legacy=0
    local platform py_major lib_dir sdk_root

    if [[ -z "$basename" ]]; then
        basename="$(_unren_detect_game_basename "$UNREN_APP")"
    fi
    sh_path="${UNREN_APP}/${basename}.sh"
    py_path="${UNREN_APP}/${basename}.py"

    platform="$(_unren_renpy_platform)"
    py_major="$(_unren_guess_python_major "$UNREN_APP" "$platform")"
    sdk_elifs="$(_unren_launcher_sdk_elif_block "$UNREN_APP" "$py_major" "$platform")"

    if ! lib_dir="$(_unren_launch_lib_dir "$UNREN_APP" "$py_major" "$platform")"; then
        echo "  No Ren'Py runtime for ${platform} in lib/ or sdk/."
        echo "  Copy UnRen-Desktop with sdk/, or use a Linux/macOS game build."
        return 0
    fi

    if _unren_runtime_needs_xwayland "$py_major" "$lib_dir"; then
        sdl_legacy=1
    fi
    sdl_block="$(_unren_launcher_sdl_block "$sdl_legacy")"

    _unren_render_launcher_sh "$sh_path" "$py_major" "$sdk_elifs" "$sdl_block"
    chmod +x "$sh_path"

    _unren_install_launcher_py "$py_path" "$py_major" "$platform"

    if [[ "$lib_dir" == "${UNREN_APP}/lib/"* ]]; then
        echo "  Launcher: ${basename}.sh (runtime: game lib/)" >&2
    else
        local sdk_slice="${lib_dir#"${UNREN_APP}/sdk/"}"
        sdk_slice="${sdk_slice%%/*}"
        echo "  Launcher: ${basename}.sh (runtime: sdk/${sdk_slice})" >&2
    fi
    if [[ "$sdl_legacy" == 1 ]]; then
        echo "  Display: SDL_VIDEODRIVER=x11 on Linux (py2 runtime)" >&2
    fi
    [[ -f "$py_path" ]] && echo "  Bootstrap: ${basename}.py (from renpy-desktop.py + SDK renpy.py)" >&2
}

unren_launch_game() {
    local basename sh_path platform py_major lib_dir

    basename="$(_unren_detect_game_basename "$UNREN_APP")"
    sh_path="${UNREN_APP}/${basename}.sh"

    echo "  Installing game launcher for ${basename} ..."
    echo
    unren_install_launcher "$basename" || return 1
    echo

    platform="$(_unren_renpy_platform)"
    py_major="$(_unren_guess_python_major "$UNREN_APP" "$platform")"
    lib_dir="$(_unren_launch_lib_dir "$UNREN_APP" "$py_major" "$platform")" || return 1

    echo "  Launching ${basename} ..."
    echo
    if [[ -f "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" ]]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON \
            sh "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" "${UNREN_APP}"
    elif [[ -f "${UNREN_ROOT}/unren/decompile-fixes.sh" ]]; then
        # shellcheck source=unren/decompile-fixes.sh
        source "${UNREN_ROOT}/unren/decompile-fixes.sh"
        unren_decompile_fixes
    fi
    _unren_configure_sdl_video "$py_major" "$lib_dir"
    set +e
    exec "${sh_path}"
    local rc=$?
    set -e
    if (( rc != 0 )); then
        echo
        echo "  Launch failed (exit ${rc})."
    fi
    return 0
}
