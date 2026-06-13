#!/usr/bin/env bash
# UnRen-Desktop — Ren'Py unpack / decompile / patch tool for Linux and macOS
# https://github.com/zujik/UnRen-Desktop

cd "$(dirname "$0")" || exit 1
UNREN_ROOT="$(pwd)"
export UNREN_ROOT

# shellcheck source=lib/config.sh
source "${UNREN_ROOT}/lib/config.sh"
# shellcheck source=lib/platform.sh
source "${UNREN_ROOT}/lib/platform.sh"
# shellcheck source=lib/runtime.sh
source "${UNREN_ROOT}/lib/runtime.sh"
# shellcheck source=lib/python-resolve.sh
source "${UNREN_ROOT}/lib/python-resolve.sh"
# shellcheck source=lib/patches.sh
source "${UNREN_ROOT}/lib/patches.sh"
# shellcheck source=lib/extract.sh
source "${UNREN_ROOT}/lib/extract.sh"
# shellcheck source=lib/decompile.sh
source "${UNREN_ROOT}/lib/decompile.sh"
# shellcheck source=lib/launch-game.sh
source "${UNREN_ROOT}/lib/launch-game.sh"
# shellcheck source=lib/menu.sh
source "${UNREN_ROOT}/lib/menu.sh"

unren_main "$@"
