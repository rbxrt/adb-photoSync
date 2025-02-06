#!/bin/bash

# Author: rbxrt
# License: MIT

# Script terminates in case of errors or the use of undefined variables
set -euo pipefail

usage () {
cat <<EOU
Usage:
  ${0##*/} <src1> [<src2> ...] <dest dir>

  Transfers photos and videos from macOS to Android via adb while retaining the chronology and folder structure.
  Requires Android SDK Platform Tools. The adb executable must be on the \$PATH.

  Wireless setup:
  1. adb pair ipaddress:dynamic-port code
  2. adb connect ipaddress:port
  3. adb devices --> ensure the device is listed.

Examples:
  ${0##*/} ~/Pictures /scdard/DCIM
    Copies all images to the phone. This command will fail if more then one Android device is connected.
EOU
} 

throw_error () {
	if [ -n "$1" ] ; then
		ERR_MESSAGE="$1"
	else
		ERR_MESSAGE='❌ Something went wrong.'
	fi

	echo "Error: $ERR_MESSAGE"$'\n' >&2
    usage >&2

	exit 1
}

progress_bar() {
    local progress=$1
    local total=$2
    local width=40  # Width of the progress bar
    local completed=$((progress * width / total))
    local remaining=$((width - completed))

    # Print progress bar
    printf "\r[%-*s] %3d%%" "$width" "$(printf '#%.0s' $(seq 1 $completed))" "$((progress * 100 / total))"
}

# Ensure ADB is installed
if ! which adb >/dev/null 2>&1; then
    throw_error '❌ adb is not on the $PATH'
fi

# Check if first argument is -dry-run
DRY_RUN=false
if [ "$1" == "-dry-run" ]; then
    DRY_RUN=true
    shift  # Remove the flag from the arguments
fi

# Ensure there are enough arguments
if [ "$#" -lt 2 ]; then
    throw_error "❌ Invalid arguments."
fi

# Get device serial
FOUND_SERIALS=("$(adb devices | grep '\t' | sed $'s/\t.*//')")
DEVICE=''

if [ ${#FOUND_SERIALS[@]} -eq 1 ]; then
    DEVICE="${FOUND_SERIALS[0]}"
fi

if [ -z "$DEVICE" ] ; then
    throw_error '❌ Check if your phone is connected. Ensure that no other device is connected at the same time.'
fi

# Target directory on Android
DEST_PATH="${!#}"
# Check if destination is writable
T="$(adb -s $DEVICE shell "[[ -d \"$DEST_PATH\" ]] && echo YES || echo NO")"

if [ "$T" == 'NO' ]; then
    throw_error '❌ Destination is not a writable directory.'
fi

# All arguments except the last are source directories
SOURCE_DIRS=("${@:1:$#-1}")
for i in "${!SOURCE_DIRS[@]}"; do
    SOURCE_DIRS[$i]="${SOURCE_DIRS[$i]%/}" # Remove trailing slash
done

# Ensure device stays awake during transfer
adb -s "$DEVICE" shell settings put global stay_on_while_plugged_in 3

# Create temp file for sorting files by modification time
TEMP_FILE=$(mktemp)

# Finish actions
trap 'adb -s "$DEVICE" shell settings put global stay_on_while_plugged_in 0; rm -f "$TEMP_FILE"' EXIT # Ensure cleanup on exit

# Collect all eligible files
for DIR in "${SOURCE_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.mp4" \) ! -name "._*" ! -name "*~" -exec stat -f "%m %N" {} + >> "$TEMP_FILE"
    else
        throw_error "❌ Source directory \"$DIR\" does not exist or is not accessible."
    fi
done

# Sort files by modification date
SORTED_FILES=$(sort -n "$TEMP_FILE" | cut -d' ' -f2-)

# Progress
FILE_COUNT=$(echo "$SORTED_FILES" | wc -l | tr -d ' ')
NUM=0  # Initialize index

# Prevent the creation of ._ files
export COPYFILE_DISABLE=1

# Process files
while IFS= read -r SRC; do
    if [ -e "$SRC" ] && [ -r "$SRC" ]; then
        NUM=$(( $NUM + 1 ))

        for DIR in "${SOURCE_DIRS[@]}"; do
            if [[ "$SRC" == "$DIR"* ]]; then
                REL_PATH="${SRC#"$DIR/"}"
                break
            fi
        done

        TARGET_DIR="$DEST_PATH/$(dirname "$REL_PATH")"
        TARGET_FILE="$DEST_PATH/$REL_PATH"

        if $DRY_RUN; then
            echo "Would transfer: $SRC → $TARGET_FILE"
        else

        (
            # Create directory structure on Android
            adb -s "$DEVICE" shell "mkdir -p \"$TARGET_DIR/\""

            # Copy file to Android
            adb -s "$DEVICE" push -q "$SRC" "$TARGET_FILE"

            # Copy compressed file to Android (slower) 
            # tar czf - -C "$(dirname "$SRC")" "$(basename "$SRC")" | adb -s "$DEVICE" shell "mkdir -p \"$TARGET_DIR/\" && tar xzf - -C \"$TARGET_DIR/\""

            # Notify Media Scanner
            adb -s "$DEVICE" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://'$TARGET_FILE'" >/dev/null

        ) < /dev/null

            progress_bar "$NUM" "$FILE_COUNT"
        fi

    else
        throw_error "❌ Source file \"$SRC\" does not exist or is not accessible."
    fi
done <<< "$SORTED_FILES"

# Exit successfully
exit 0
