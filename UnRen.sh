#!/usr/bin/env bash
# UnRen-Desktop — Ren'Py unpack / decompile / patch tool for Linux and macOS
# https://github.com/zujik/UnRen-Desktop

set -euo pipefail

UNREN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export UNREN_ROOT

if [[ ! -f "${UNREN_ROOT}/unren/config.sh" ]]; then
    cat >&2 <<EOF
Error: incomplete UnRen-Desktop install.

Missing: ${UNREN_ROOT}/unren/config.sh

Copy the full UnRen-Desktop folder into the game (all of tools/, patches/, sdk/, unren/, etc.).

Ren'Py games already use lib/ for Python — UnRen bash modules live in unren/, not lib/.

  GameFolder/UnRen.sh
  GameFolder/unren/
  GameFolder/tools/
  ...

Or run from the repo:

  /path/to/UnRen-Desktop/UnRen.sh /path/to/GameFolder
EOF
    exit 1
fi

# shellcheck source=unren/config.sh
source "${UNREN_ROOT}/unren/config.sh"
# shellcheck source=unren/platform.sh
source "${UNREN_ROOT}/unren/platform.sh"
# shellcheck source=unren/sdk-resolve.sh
source "${UNREN_ROOT}/unren/sdk-resolve.sh"
# shellcheck source=unren/runtime.sh
source "${UNREN_ROOT}/unren/runtime.sh"
# shellcheck source=unren/python-resolve.sh
source "${UNREN_ROOT}/unren/python-resolve.sh"
# shellcheck source=unren/patches.sh
source "${UNREN_ROOT}/unren/patches.sh"
# shellcheck source=unren/extract.sh
source "${UNREN_ROOT}/unren/extract.sh"
# shellcheck source=unren/decompile.sh
source "${UNREN_ROOT}/unren/decompile.sh"
# shellcheck source=unren/launch-game.sh
source "${UNREN_ROOT}/unren/launch-game.sh"
# shellcheck source=unren/menu.sh
source "${UNREN_ROOT}/unren/menu.sh"

unren_main "$@"
