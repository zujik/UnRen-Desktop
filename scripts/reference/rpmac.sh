#!/bin/bash
#
# Reference copy — not invoked by UnRen-Desktop.
#
# Author: F.Rvv3 (F95zone thread; account since deleted)
#   https://f95zone.to/threads/rpmac-automatic-renpy-game-converter-for-mac.287097/
# Last modified (upstream): 2026-02-24
#
# Purpose: repackage non-Mac games onto a full macOS SDK tree (GameName-MacOS/).
# UnRen-Desktop borrows only version detection + download patterns — see scripts/download-sdk.sh.
#
# Description:
#     This script simplifies the conversion process of non-Mac Ren'Py games.
#	  It will automatically detect SDK version, download it if missing, and copy game files.
# Author:
#	  F.Rvv3
# Last modified:
#	  2026-02-24 22:20
#
# TODO: accept multiple games at once?
# TODO: add linux option?

set -euo pipefail

# Globals: user variables
readonly SDK_DIR="${HOME}/Documents/RenpySDK"
readonly DESTINATION_SUFFIX="-MacOS"
# Globals: script options
copy_all=false
sdk_only=false
use_latest=false
overwrite=false
trash_files=false
version_only=false
noconfirm=false
pos_args=()
# Globals: escape sequences
BLUE='\033[34m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NC='\033[0m'

# Displays a spinner to indicate work
# Arguments:
#	Process identifier, integer.
#	Message, string (optional).
display_spinner() {
	local pid=$1
	local frame_width=5
	local frame_count=6
	local spinner="[=  ][== ][===][ ==][  =][   ]"
	local message='Working'
	if [[ -n $2 ]]; then
		message=$2
	fi
	i=0
	sleep 0.5
	while kill -0 "$pid" 2>/dev/null; do
		local offset=$((i * frame_width))
		printf "\r\033[K%b%s %b%s%b" "$BLUE" "$message" "$YELLOW" "${spinner:$offset:$frame_width}" "$NC"
		i=$(((i + 1) % frame_count))
		sleep .1
	done
	printf "\r\033[K%b%s %bDone!%b\n" "$BLUE" "$message" "$GREEN" "$NC"
}

# Converts bytes to human-readable format
# Arguments:
#	Bytes, integer.
bytestohuman() {
	local i=${1:-0} s=0 S=("B" "KB" "MB" "GB" "TB" "PB" "EB")
	while ((i >= 1000 && s < ${#S[@]} - 1)); do
		i=$(((i + 500) / 1000))
		s=$((s + 1))
	done
	echo "$i ${S[$s]}"
}

# Downloads specified Ren'Py SDK for Mac from renpy.org
# Globals:
#	SDK_DIR
# Arguments:
#	SDK version, string.
download_sdk() {
	local sdk_version=$1
	local dest_dir=$SDK_DIR
	local filename="renpy-${sdk_version}-sdk.tar.bz2"
	local url="https://www.renpy.org/dl/${sdk_version}/${filename}"
	local tmp_file="/tmp/${filename}"

	mkdir -p "$dest_dir"
	printf "\n%b-------------------------------------------%b\n" "$BLUE" "$NC"
	printf "%bDownloading Ren'Py %s for macOS%b\n" "$BLUE" "$sdk_version" "$NC"
	curl -Lf -o "$tmp_file" "$url" || {
		err "Curl failed to download RenPy SDK."
		exit 1
	}
	printf "%bExtracting %s to %s%b\n" "$BLUE" "$tmp_file" "$dest_dir" "$NC"
	tar -xjf "$tmp_file" -C "$dest_dir" || {
		err "Failed to extract RenPy SDK."
		exit 1
	}
	printf "%bUpdating permissions%b\n" "$BLUE" "$NC"
	xattr -rd com.apple.quarantine "$dest_dir/renpy-${sdk_version}-sdk" 2>/dev/null
	rm -f "$tmp_file"
	printf "%bDone!\n-------------------------------------------%b\n\n" "$BLUE" "$NC"
}

# Retrieves latest Ren'Py SDK version from renpy.org/latest
# Returns:
#	Version, string.
fetch_latest_sdk_version() {
	local url="https://www.renpy.org/latest.html"
	curl -sL "$url" | grep -Eo 'https://[^"]+sdk\.tar\.bz2' | head -n 1 | cut -d"/" -f 5
}

# Displays a warning
# Arguments:
#	Message, string.
warn() {
	printf "%bWarning:%b $1" "$YELLOW" "$NC"
}

# Displays an error
# Arguments:
#	Message, string.
err() {
	printf "%bError:%b $1" "$RED" "$NC"
}

show_help() {
	cat <<EOF
Usage: ${0##*/} [-adhlotvy] <game directory>

Description:
    Converts Ren'Py games made for other platforms to MacOS games.

Options:
    -a          Copy all game files (walkthroughs, bonus content, etc.)
    -d          Download SDK and exit.
    -h          Display this help and exit.
    -l          Use latest SDK.
    -o          Overwrite existing files and folders
    -t          Trash original game folder after conversion is done.
    -v          Display game SDK version and exit.
    -y          Silent mode, don't ask for confirmation.
EOF
}

# Parsing script options
while [[ $# -gt 0 ]]; do
	case "$1" in
	-a | --all)
		copy_all=true
		shift
		;;
	-d | --download-sdk)
		sdk_only=true
		shift
		;;
	-h | --help)
		show_help
		exit 0
		;;
	-l | --use-latest)
		use_latest=true
		shift
		;;
	-o | --overwrite)
		overwrite=true
		shift
		;;
	-t | --trash)
		trash_files=true
		shift
		;;
	-v | --sdk-version)
		version_only=true
		shift
		;;
	-y | --noconfirm)
		noconfirm=true
		shift
		;;
	--)
		shift
		break
		;;
	-[!:-]*)
		# Match any short flag combo (e.g., -ta) but not --long-flags
		optstr="${1#-}"
		while [ -n "$optstr" ]; do
			char="${optstr:0:1}"
			case "$char" in
			h)
				show_help
				exit 0
				;;
			a) copy_all=true ;;
			d) sdk_only=true ;;
			l) use_latest=true ;;
			o) overwrite=true ;;
			t) trash_files=true ;;
			v) version_only=true ;;
			y) noconfirm=true ;;
			*)
				err "Unknown flag '-$char'. See help(-h) for all available options."
				exit 1
				;;
			esac
			optstr="${optstr:1}"
		done
		shift
		;;
	-*)
		err "Unknown flag '-$char'. See help(-h) for all available options."
		exit 1
		;;
	*)
		pos_args+=("$1")
		shift
		;;
	esac
done

# Validating positional arguments
if [ "${#pos_args[@]}" -eq 0 ]; then
	show_help
	exit 1
fi
if [ "${#pos_args[@]}" -gt 1 ]; then
	warn "Too many arguments. This script works with one game folder at a time."
	exit 1
fi

# Using cd and pwd to get absolute path
target_path=$(cd "${pos_args[0]}" 2>/dev/null && pwd)
target_name=$(basename "$target_path")
target_parent_path=$(dirname "$target_path")
destination_path="$target_parent_path/${target_name}${DESTINATION_SUFFIX}"

# Quit if target does not exist
if [[ ! -d "$target_path" ]]; then
	err "Provided game directory does not exist."
	exit 1
fi

# Quit if game files are missing
if [ ! -d "$target_path/game" ]; then
	err "'game' folder not found in $target_path\n"
	exit 1
fi

# Quit if converted game already exists and overwrite is turned off
if [[ "$overwrite" == "false" && -d "$destination_path" ]]; then
	printf "%bConverted game already exists at:%b\n%s\n" "$YELLOW" "$NC" "$destination_path"
	printf "%bMove it, or use -o flag to overwrite automatically.%b" "$YELLOW" "$NC"
	exit 1
fi

printf "%bTarget:%b %s\n" "$GREEN" "$NC" "$target_path"

# Trying to determine SDK version
sdk_version=$(
	perl -nle '
	if (/\b(?:vc_)?version\s*=\s*[\x22\x27]?([\d.a-zA-Z]+)/) { 
        my $v = $1; 
        $v =~ s/\.\d{4,}$//;
        print $v if $v =~ /\./; 
	}
	' "$target_path"/renpy/vc_version.py
)

if [[ -z "$sdk_version" ]]; then
	sdk_version=$(
		perl -nle '
		if (/version_tuple\s*=\s*\((.*?)\)/) {
			my @nums = $1 =~ /(\d+)/g;
			$last_version = join(".", @nums);
		}
		END { print $last_version if $last_version }
		' "$target_path"/renpy/__init__.py
	)
fi

if [[ -n "$sdk_version" ]]; then
	printf "%bTarget SDK:%b %s\n" "$GREEN" "$NC" "$sdk_version"
else
	err "Failed to determine SDK version."
	if [[ "$use_latest" == "false" ]]; then
		exit 1
	fi
fi

if $version_only; then
	exit 0
fi

# Quit if game is older than 6.11
if [[ -n "$sdk_version" ]]; then
	major=$(echo "$sdk_version" | cut -d. -f 1)
	minor=$(echo "$sdk_version" | cut -d. -f 2)
	if [[ "$major" -eq "6" && "$minor" -lt "11" ]]; then
		err "This game is too old to convert (SDK version less than 6.11)."
		exit 1
	fi
fi

# Fetch latest SDK version
if [[ "$use_latest" == "true" ]]; then
	sdk_version=$(fetch_latest_sdk_version)
	if [[ -z "$sdk_version" ]]; then
		err "Failed to fetch latest SDK version."
		exit 1
	fi
fi

# Locating MacOS SDK
sdk_source="${SDK_DIR}/renpy-$sdk_version-sdk"

if [ ! -d "$sdk_source" ]; then
	if [[ "$sdk_only" == true || "$noconfirm" == true ]]; then
		REPLY="Y"
	else
		printf "\n%bWarning:%b SDK version %s not found in %s\n" "$YELLOW" "$NC" "$sdk_version" "$SDK_DIR"
		printf "%bDo you want to download it right now? [Y/n]: %b" "$YELLOW" "$NC"
		read -n 1 -r
	fi
	if [[ -z $REPLY || $REPLY =~ ^[Yy]$ ]]; then
		download_sdk "$sdk_version"
	else
		exit 0
	fi
fi

printf "%bLocal SDK:%b %s" "$GREEN" "$NC" "$sdk_source"

if $sdk_only; then
	exit 0
fi

printf "\n\n"

# Copying MacOS SDK
rm -rf "$destination_path"
size=$(du -hs "$sdk_source" | awk '{print $1}')
cp -R "$sdk_source" "$destination_path" 1>/dev/null &
display_spinner $! "Copying SDK (${size})"

# Copying game files
size=$(du -hs "$target_path/game" | awk '{print $1}')
cp -R "$target_path/game" "$destination_path/" 1>/dev/null &
display_spinner $! "Copying game files (${size})"

# Copying extra files
if $copy_all; then
	EXCLUDED_FILES=("game" "lib" "renpy" "log.txt" ".git" "*.app" "*.exe" "*.sh" "*.py" ".[!.]*")
	exclude_flags=()
	for item in "${EXCLUDED_FILES[@]}"; do
		exclude_flags+=("--exclude=$item")
	done
	raw_stats=$(rsync -av --dry-run --stats "${exclude_flags[@]}" "$target_path/" "$destination_path")
	size_line=$(echo "$raw_stats" | grep "Total file size")
	byte_size=$(echo "$size_line" | tr -cd '0-9')
	file_line=$(echo "$raw_stats" | grep "Number of files transferred")
	file_num=$(echo "$file_line" | tr -cd '0-9')
	if [[ "$file_num" -gt 0 ]]; then
		rsync -av "${exclude_flags[@]}" "$target_path/" "$destination_path" 1>/dev/null &
		display_spinner $! "Copying extra files ($(bytestohuman "$byte_size"))"
	else
		warn "No extra files found\n"
	fi
fi

# Updating persmissions
xattr -rd com.apple.quarantine "${destination_path}" 1>/dev/null &
display_spinner $! "Updating permissions"

# Trashing old game
if $trash_files; then
	osascript -e "tell application \"Finder\" to delete POSIX file \"${target_path}\"" &>/dev/null &
	display_spinner $! "Moving old game to trash"
fi

printf "\n%bAll done!%b Enjoy your game!\n" "$GREEN" "$NC"
