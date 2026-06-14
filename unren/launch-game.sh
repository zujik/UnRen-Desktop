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

_unren_launcher_stdlib_shell_guard() {
    local app="$1" lib_rel="$2"
    local lib_dir="${app}/${lib_rel}"
    local -a parts=() candidate rel

    for candidate in \
        "${lib_dir}/lib/python2.7/site.py" \
        "${lib_dir}/lib/python2.3/site.py" \
        "${app}/lib/python2.7/site.py" \
        "${app}/lib/python3.12/site.py" \
        "${app}/lib/python3.12/site.pyc" \
        "${app}/lib/python3.9/site.py" \
        "${lib_dir}/lib/python3.12/site.py" \
        "${lib_dir}/lib/python3.12/site.pyc" \
        "${lib_dir}/lib/python3.9/site.py" \
        "${app}/lib/pythonlib2.7/site.py"; do
        [[ -f "$candidate" ]] || continue
        rel="${candidate#"${app}/"}"
        parts+=("[ -f \"\$ROOT/${rel}\" ]")
    done

    ((${#parts[@]} == 0)) && return 1
    printf ' && { %s; }' "$(IFS=' || '; echo "${parts[*]}")"
}

_unren_runtime_py_major_for_lib() {
    local py_major="$1" lib_dir="$2"
    case "$lib_dir" in
        */py3-*|*/python3.*) printf '3\n' ;;
        *) printf '%s\n' "$py_major" ;;
    esac
}

_unren_game_pythonhome_for_lib() {
    local app="$1" lib_dir="$2" candidate

    for candidate in \
        "${lib_dir}/lib/python2.7" \
        "${lib_dir}/lib/python2.3" \
        "${app}/lib/python2.7" \
        "${app}/lib/python3.12" \
        "${app}/lib/python3.9" \
        "${lib_dir}/lib/python3.12" \
        "${lib_dir}/lib/python3.9" \
        "${app}/lib/pythonlib2.7"; do
        if _unren_pythonhome_has_stdlib "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

_unren_game_lib_usable() {
    local app="$1" lib_dir="$2"
    [[ -d "$lib_dir" ]] || return 1
    [[ -x "${lib_dir}/renpy" || -x "${lib_dir}/python" || -x "${lib_dir}/python.real" ]] || return 1
    _unren_game_pythonhome_for_lib "$app" "$lib_dir" >/dev/null
}

_unren_legacy_game_lib_dir() {
    local app="$1" platform="$2" legacy=""

    case "$platform" in
        linux-x86_64) legacy="${app}/lib/linux-x86_64" ;;
        linux-i686) legacy="${app}/lib/linux-i686" ;;
        mac-universal|darwin-*|Darwin-*)
            if [[ -d "${app}/lib/darwin-arm64" ]]; then
                legacy="${app}/lib/darwin-arm64"
            else
                legacy="${app}/lib/darwin-x86_64"
            fi
            ;;
    esac

    if [[ -n "$legacy" && -d "$legacy" ]] && {
        [[ -x "${legacy}/renpy" || -x "${legacy}/python" || -x "${legacy}/python.real" ]]
    } && _unren_game_lib_usable "$app" "$legacy"; then
        printf '%s\n' "$legacy"
        return 0
    fi
    return 1
}

_unren_launcher_game_lib_if_block() {
    local app="$1" py_major="$2" platform="$3"
    local game_lib legacy rel kw="if"

    game_lib="${app}/lib/py${py_major}-${platform}"
    if _unren_game_lib_usable "$app" "$game_lib"; then
        rel="${game_lib#"${app}/"}"
        if guard="$(_unren_launcher_stdlib_shell_guard "$app" "$rel")"; then
            printf '%s\n' \
                "${kw} [ -d \"\$ROOT/${rel}\" ] && { [ -x \"\$ROOT/${rel}/renpy\" ] || [ -x \"\$ROOT/${rel}/python\" ]; }${guard}; then" \
                "    LIB=\"\$ROOT/${rel}\""
            kw="elif"
        fi
    fi

    case "$platform" in
        linux-x86_64) legacy="${app}/lib/linux-x86_64" ;;
        linux-i686) legacy="${app}/lib/linux-i686" ;;
        mac-universal|darwin-*|Darwin-*)
            if [[ -d "${app}/lib/darwin-arm64" ]]; then
                legacy="${app}/lib/darwin-arm64"
            else
                legacy="${app}/lib/darwin-x86_64"
            fi
            ;;
        *) legacy="" ;;
    esac

    if [[ -n "$legacy" ]] && _unren_game_lib_usable "$app" "$legacy"; then
        rel="${legacy#"${app}/"}"
        if guard="$(_unren_launcher_stdlib_shell_guard "$app" "$rel")"; then
            printf '%s\n' \
                "${kw} [ -d \"\$ROOT/${rel}\" ] && { [ -x \"\$ROOT/${rel}/renpy\" ] || [ -x \"\$ROOT/${rel}/python\" ] || [ -x \"\$ROOT/${rel}/python.real\" ]; }${guard}; then" \
                "    LIB=\"\$ROOT/${rel}\""
            kw="elif"
        fi
    fi

    printf '%s\n' "$kw"
}

_unren_launch_lib_dir() {
    local app="$1" py_major="$2" platform="$3"
    local game_lib sdk_root sdk_lib legacy

    game_lib="${app}/lib/py${py_major}-${platform}"
    if [[ -d "$game_lib" ]]; then
        chmod -f +x "${game_lib}/python" "${game_lib}/renpy" "${game_lib}/"* 2>/dev/null || true
    fi
    if [[ -d "$game_lib" ]] && {
        [[ -x "${game_lib}/renpy" || -x "${game_lib}/python" ]]
    } && _unren_game_lib_usable "$app" "$game_lib"; then
        printf '%s\n' "$game_lib"
        return 0
    fi

    if legacy="$(_unren_legacy_game_lib_dir "$app" "$platform")"; then
        printf '%s\n' "$legacy"
        return 0
    fi

    if _unren_resolve_sdk_runtime "$app" "$py_major" "$platform" sdk_root sdk_lib; then
        printf '%s\n' "$sdk_lib"
        return 0
    fi

    return 1
}

_unren_launcher_root_path() {
    local app="$1" path="$2"
    local app_real path_real dir base rel

    [[ -n "$path" ]] || return 1
    app_real="$(cd -P "$app" 2>/dev/null && pwd)" || app_real="$app"
    if [[ -d "$path" ]]; then
        path_real="$(cd -P "$path" && pwd)"
    else
        dir="$(dirname "$path")"
        base="$(basename "$path")"
        path_real="$(cd -P "$dir" 2>/dev/null && pwd)/${base}"
    fi

    if [[ "$path_real" == "${app_real}/"* ]]; then
        printf '%s\n' "${path_real#"${app_real}/"}"
        return 0
    fi
    if rel="$(realpath --relative-to="$app_real" "$path_real" 2>/dev/null)" \
        && [[ -n "$rel" && "$rel" != ".." && "$rel" != ../* ]]; then
        printf '%s\n' "$rel"
        return 0
    fi
    printf '%s\n' "$path_real"
}

_unren_launcher_path_shell() {
    local app="$1" path="$2"
    local rel

    rel="$(_unren_launcher_root_path "$app" "$path")"
    if [[ "$rel" == /* ]]; then
        printf '%s\n' "$rel"
    else
        printf '$ROOT/%s\n' "$rel"
    fi
}

_unren_launcher_sdk_elif_block() {
    local app="$1" py_major="$2" platform="$3" kw="${4:-elif}"
    local slice sdk_root lib_dir rel_lib phome py_args layout ld_line
    local lib_shell phome_shell sdk_shell

    while IFS= read -r slice; do
        [[ -n "$slice" ]] || continue
        local slice_py
        sdk_root="$(_unren_sdk_slice_dir "$slice" "$app")"
        slice_py="$(_unren_sdk_slice_py_major "$slice")"
        lib_dir="$(_unren_sdk_lib_dir "$sdk_root" "$slice_py" "$platform")" || continue
        _unren_sdk_lib_usable "$lib_dir" || continue
        _unren_sdk_runtime_usable "$slice" "$sdk_root" "$lib_dir" || continue

        phome="$(_unren_sdk_pythonhome "$sdk_root" "$lib_dir")"
        rel_lib="$(_unren_launcher_root_path "$app" "$lib_dir")"
        py_args="$(_unren_sdk_py_args "$sdk_root")"
        layout="$(_unren_sdk_layout "$sdk_root")"
        lib_shell="$(_unren_launcher_path_shell "$app" "$lib_dir")"
        sdk_shell="$(_unren_launcher_path_shell "$app" "$sdk_root")"
        local sdk_pyhome_line=""
        if [[ -n "$phome" ]]; then
            phome_shell="$(_unren_launcher_path_shell "$app" "$phome")"
            sdk_pyhome_line="    SDK_PYHOME=\"${phome_shell}\""
        fi
        case "$layout" in
            renpy6|renpy5)
                ld_line='    SDK_LD_PATH="$LIB:$LIB/lib"'
                renpy_py_line="    SDK_RENPY_PY=\"${sdk_shell}/renpy.py\""
                ;;
        *)
            ld_line='    SDK_LD_PATH="$LIB"'
            case "$slice" in
                py2-*)
                    renpy_py_line="    SDK_RENPY_PY=\"${sdk_shell}/renpy.py\""
                    ;;
                *)
                    renpy_py_line=""
                    ;;
            esac
                ;;
        esac

        if [[ "$rel_lib" == /* ]]; then
            printf '%s\n' \
                "${kw} [ -d \"${rel_lib}\" ] && { [ -x \"${rel_lib}/renpy\" ] || [ -x \"${rel_lib}/python\" ] || [ -x \"${rel_lib}/python.real\" ]; }; then" \
                "    LIB=\"${rel_lib}\""
        else
            printf '%s\n' \
                "${kw} [ -d \"\$ROOT/${rel_lib}\" ] && { [ -x \"\$ROOT/${rel_lib}/renpy\" ] || [ -x \"\$ROOT/${rel_lib}/python\" ] || [ -x \"\$ROOT/${rel_lib}/python.real\" ]; }; then" \
                "    LIB=\"\$ROOT/${rel_lib}\""
        fi
        [[ -n "$sdk_pyhome_line" ]] && printf '%s\n' "$sdk_pyhome_line"
        printf '%s\n' \
            "    SDK_PY_ARGS=\"${py_args}\"" \
            "$ld_line"
        [[ -n "$renpy_py_line" ]] && printf '%s\n' "$renpy_py_line"
        kw="elif"
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
    local dest="$1" py_major="$2" game_lib_if="$3" sdk_elifs="$4" sdl_block="$5"
    local tmp_game tmp_elifs tmp_sdl

    if [[ ! -f "$LAUNCHER_SH_TEMPLATE" ]]; then
        unren_die "Launcher template missing: ${LAUNCHER_SH_TEMPLATE}"
    fi

    tmp_game="$(mktemp)"
    tmp_elifs="$(mktemp)"
    tmp_sdl="$(mktemp)"
    printf '%s' "$game_lib_if" >"$tmp_game"
    printf '%s' "$sdk_elifs" >"$tmp_elifs"
    printf '%s' "$sdl_block" >"$tmp_sdl"

    env -u PYTHONHOME -u PYTHONPATH python3 - "$LAUNCHER_SH_TEMPLATE" "$dest" "$py_major" "$tmp_game" "$tmp_elifs" "$tmp_sdl" <<'PY'
import pathlib
import re
import sys

template_path, dest, py_major, game_path, elifs_path, sdl_path = sys.argv[1:7]
content = pathlib.Path(template_path).read_text()
content = content.replace("\r\n", "\n").replace("\r", "\n")

def read_block(path: str) -> str:
    p = pathlib.Path(path)
    if not p.is_file():
        return ""
    return p.read_text().replace("\r\n", "\n").replace("\r", "\n")

replacements = {
    "@@UNREN_PY_MAJOR@@": py_major,
    "@@UNREN_GAME_LIB_IF@@": read_block(game_path),
    "@@UNREN_SDK_ELIFS@@": read_block(elifs_path),
    "@@UNREN_SDL_BLOCK@@": read_block(sdl_path),
}
for token, block in replacements.items():
    content = re.sub(re.escape(token) + r"\s*", block, content)

if "@@UNREN_" in content:
    raise SystemExit("launcher template still has unreplaced placeholders")

pathlib.Path(dest).write_text(content)
PY

    if [[ ! -f "$dest" ]] || grep -q '@@UNREN_' "$dest" 2>/dev/null; then
        rm -f "$tmp_game" "$tmp_elifs" "$tmp_sdl"
        unren_die "Failed to generate launcher script (template placeholders remain)."
    fi

    rm -f "$tmp_game" "$tmp_elifs" "$tmp_sdl"
}

_unren_sync_native_renpy_modules() {
    local app="$1" platform="$2"
    local src dst base

    case "$platform" in
        linux-x86_64) src="${app}/lib/linux-x86_64/lib/python2.7/renpy" ;;
        linux-i686) src="${app}/lib/linux-i686/lib/python2.7/renpy" ;;
        *) return 0 ;;
    esac

    dst="${app}/renpy"
    [[ -d "$src" && -d "$dst" ]] || return 0

    for so in "$src"/*.so; do
        [[ -f "$so" ]] || continue
        base="$(basename "$so")"
        if [[ ! -f "${dst}/${base}" ]]; then
            /bin/cp -af "$so" "${dst}/${base}"
            echo "  + renpy/${base} (from game lib)" >&2
        fi
    done
}

_unren_patch_launcher_sdk_renpy_base() {
    local dest="$1"
    [[ -f "$dest" ]] || return 0
    if grep -q 'UNREN_SDK_SYS_PATH' "$dest" 2>/dev/null; then
        return 0
    fi
    env -u PYTHONHOME -u PYTHONPATH python3 - "$dest" <<'PY'
import pathlib
import re
import sys

dest = pathlib.Path(sys.argv[1])
text = dest.read_text()

sdk_block = """    renpy_base = path_to_renpy_base()

    # UNREN_SDK_RENPY_BASE - SDK native modules need the matching sdk/renpy tree.
    import os as _unren_os
    _unren_game_root = _unren_os.path.dirname(_unren_os.path.abspath(__file__))
    _unren_sdk = _unren_os.environ.get("UNREN_SDK_ROOT", "")
    _unren_use_sdk = False
    if _unren_sdk and _unren_os.path.isdir(_unren_os.path.join(_unren_sdk, "renpy")):
        renpy_base = _unren_os.path.abspath(_unren_sdk)
        _unren_use_sdk = True

"""

sys_path_block = """    # UNREN_SDK_SYS_PATH - game dir is sys.path[0]; put SDK renpy first when using sdk/.
    if _unren_use_sdk:
        _unren_gr = _unren_os.path.normpath(_unren_game_root)
        sys.path[:] = [p for p in sys.path if _unren_os.path.normpath(p or "") != _unren_gr]
        sys.path.insert(0, renpy_base)
    else:
        sys.path.append(renpy_base)

"""

text, n = re.subn(
    r"    renpy_base = path_to_renpy_base\(\)\n(?:    # UNREN_SDK_RENPY_BASE[^\n]*\n(?:    import os as _unren_os\n    _unren_sdk[^\n]*\n    if _unren_sdk[^\n]*\n        renpy_base[^\n]*\n)?)?",
    sdk_block,
    text,
    count=1,
)
if n == 0 and "    renpy_base = path_to_renpy_base()\n" in text:
    text = text.replace("    renpy_base = path_to_renpy_base()\n", sdk_block, 1)
    n = 1
if n == 0:
    sys.exit(0)

if "    sys.path.append(renpy_base)\n" not in text:
    sys.exit(0)
text = text.replace("    sys.path.append(renpy_base)\n", sys_path_block, 1)
dest.write_text(text)
PY
}

_unren_patch_launcher_native_renpy() {
    local dest="$1"
    [[ -f "$dest" ]] || return 0
    if grep -q 'UNREN_NATIVE_RENPY_PATH' "$dest" 2>/dev/null; then
        return 0
    fi
    env -u PYTHONHOME -u PYTHONPATH python3 - "$dest" <<'PY'
import pathlib
import sys

dest = pathlib.Path(sys.argv[1])
text = dest.read_text()
needle = "    sys.path.append(renpy_base)\n"
snippet = """    # UNREN_NATIVE_RENPY_PATH - append game lib/*.so dir after renpy_base (Windows PC builds).
    import os as _unren_os
    _unren_base = _unren_os.path.dirname(_unren_os.path.abspath(__file__))
    for _unren_rel in (
        "lib/linux-x86_64/lib/python2.7",
        "lib/linux-i686/lib/python2.7",
        "lib/py2-linux-x86_64/lib/python2.7",
        "lib/py2-linux-i686/lib/python2.7",
        "lib/darwin-arm64/lib/python2.7",
        "lib/darwin-x86_64/lib/python2.7",
    ):
        _unren_p = _unren_os.path.join(_unren_base, _unren_rel)
        if _unren_os.path.isfile(_unren_os.path.join(_unren_p, "renpy", "parsersupport.so")):
            sys.path.append(_unren_p)
            break

"""
if needle not in text:
    sys.exit(0)
dest.write_text(text.replace(needle, snippet + needle, 1))
PY
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
    _unren_patch_launcher_native_renpy "$dest"
    _unren_patch_launcher_sdk_renpy_base "$dest"
    chmod +x "$dest" 2>/dev/null || true
}

_unren_try_ensure_sdk_runtime() {
    local app="$1" py_major="$2" platform="$3"
    local sdk_root sdk_lib script

    if _unren_resolve_sdk_runtime "$app" "$py_major" "$platform" sdk_root sdk_lib; then
        return 0
    fi

    # Never auto-download or mutate sdk/ unless explicitly requested.
    [[ "${UNREN_FETCH_SDK:-}" == 1 ]] || return 1

    script="${UNREN_ROOT}/scripts/ensure-sdk-runtime.sh"
    [[ -f "$script" ]] || return 1
    chmod +x "$script" 2>/dev/null || true

    echo "  UNREN_FETCH_SDK=1 — fetching Linux libs from renpy.org (will not overwrite working sdk/) ..."
    echo
    if ! RENPY_PLATFORM="$platform" UNREN_APP="$app" bash "$script" "$app"; then
        return 1
    fi
    echo
    _unren_resolve_sdk_runtime "$app" "$py_major" "$platform" sdk_root sdk_lib
}

unren_install_launcher() {
    local basename="${1-}" sh_path py_path game_lib_if sdk_elifs sdk_kw launcher_pick sdl_block sdl_legacy=0
    local platform py_major lib_dir renpy_major sdk_root

    # Launcher install uses system python3 helpers; never inherit game PYTHONHOME.
    unset PYTHONHOME PYTHONPATH

    if [[ -z "$basename" ]]; then
        basename="$(_unren_detect_game_basename "$UNREN_APP")"
    fi
    sh_path="${UNREN_APP}/${basename}.sh"
    py_path="${UNREN_APP}/${basename}.py"

    platform="$(_unren_renpy_platform)"
    py_major="$(_unren_guess_python_major "$UNREN_APP" "$platform")"
    renpy_major="$(_unren_script_version_major_from_app "$UNREN_APP")"
    launcher_pick="$(_unren_launcher_game_lib_if_block "$UNREN_APP" "$py_major" "$platform")"
    sdk_kw="$(printf '%s\n' "$launcher_pick" | tail -1)"
    game_lib_if="$(printf '%s\n' "$launcher_pick" | sed '$d' | sed '/^[[:space:]]*$/d')"

    if [[ -z "$game_lib_if" ]]; then
        sdk_kw="if"
        if [[ -d "${UNREN_APP}/lib/linux-x86_64" || -d "${UNREN_APP}/lib/py${py_major}-${platform}" ]]; then
            echo "  Note: game lib/ has no usable Python stdlib (common on Windows-only builds) — trying sdk/"
            echo
        fi
    fi

    if ! _unren_resolve_sdk_runtime "$UNREN_APP" "$py_major" "$platform" sdk_root sdk_lib; then
        _unren_try_ensure_sdk_runtime "$UNREN_APP" "$py_major" "$platform" || true
    fi

    sdk_elifs="$(_unren_launcher_sdk_elif_block "$UNREN_APP" "$py_major" "$platform" "$sdk_kw")"

    if [[ -z "$game_lib_if" && -n "$sdk_elifs" ]]; then
        sdk_elifs="$(printf '%s\n' "$sdk_elifs" | sed '1s/^elif /if /')"
    fi

    if [[ -z "$game_lib_if" && -z "$sdk_elifs" ]]; then
        echo "  Cannot generate launcher: no lib/ or sdk/ runtime matched."
        echo "  Populate sdk first: ${UNREN_ROOT}/scripts/populate-sdk-from-sources.sh"
        echo "  Then copy sdk/py3-8.5.3/lib/py3-linux-x86_64/ into this game."
        return 0
    fi

    if ! lib_dir="$(_unren_launch_lib_dir "$UNREN_APP" "$py_major" "$platform")"; then
        _unren_try_ensure_sdk_runtime "$UNREN_APP" "$py_major" "$platform" || true
        sdk_elifs="$(_unren_launcher_sdk_elif_block "$UNREN_APP" "$py_major" "$platform" "$sdk_kw")"
        lib_dir="$(_unren_launch_lib_dir "$UNREN_APP" "$py_major" "$platform")" || lib_dir=""
    fi

    if [[ -z "$lib_dir" ]]; then
        echo "  No Ren'Py runtime for ${platform} in lib/ or sdk/."
        if [[ -d "${UNREN_APP}/sdk/py3-8.5.3" || -d "${UNREN_APP}/sdk/py2-7.8.7" ]]; then
            echo "  sdk/ exists but has no usable lib/py*-linux-x86_64/python."
            echo "  If UnRen-Desktop elsewhere has a working sdk/, copy sdk/py3-8.5.3 into this game."
            echo "  To fetch once (non-destructive): UNREN_FETCH_SDK=1 ./UnRen.sh  (then option g)"
            echo "  Or: ./scripts/ensure-sdk-runtime.sh  (skips if Linux python already present)"
        else
            echo "  Copy sdk/ from a working UnRen-Desktop, or: UNREN_FETCH_SDK=1 then option g"
        fi
        return 0
    fi

    local runtime_py_major
    runtime_py_major="$(_unren_runtime_py_major_for_lib "$py_major" "$lib_dir")"

    if [[ "$lib_dir" == *"/sdk/py3-"* ]] && (( renpy_major > 0 && renpy_major < 8 )); then
        echo "  Note: Ren'Py ${renpy_major} game using py3 SDK fallback (populate py2-7.8.7 for native py2)."
        echo "  Post-decompile py2 print fixes run automatically before launch."
        echo
    fi

    if _unren_runtime_needs_xwayland "$runtime_py_major" "$lib_dir"; then
        sdl_legacy=1
    fi
    sdl_block="$(_unren_launcher_sdl_block "$sdl_legacy")"

    _unren_sync_native_renpy_modules "$UNREN_APP" "$platform"
    _unren_render_launcher_sh "$sh_path" "$runtime_py_major" "$game_lib_if" "$sdk_elifs" "$sdl_block"
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

    local runtime_py_major
    runtime_py_major="$(_unren_runtime_py_major_for_lib "$py_major" "$lib_dir")"

    echo "  Launching ${basename} ..."
    echo
    if [[ -f "${UNREN_ROOT}/unren/decompile-fixes.sh" ]]; then
        # shellcheck source=unren/decompile-fixes.sh
        source "${UNREN_ROOT}/unren/decompile-fixes.sh"
        unren_decompile_fixes
    elif [[ -f "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" ]]; then
        env -u PYTHONHOME -u PYTHONPATH -u UNREN_PYTHON \
            sh "${UNREN_ROOT}/tools/decompile-fixes/run-all.sh" "${UNREN_APP}"
    fi
    _unren_configure_sdl_video "$runtime_py_major" "$lib_dir"
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
