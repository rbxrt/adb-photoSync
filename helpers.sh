#!/bin/bash

# Author: rbxrt
# License: MIT

usage () {
cat <<EOU
Usage:
    ${0##*/} <action> <arg1> [<arg2> ...]

    Transfers photos and videos from macOS to Android via adb while retaining the chronology and folder structure.
    Requires Android SDK Platform Tools. The adb executable must be on the \$PATH.

Examples:
    ${0##*/} push ~/Pictures /scdard/DCIM
        Copies all images from your Pictures folder to the phone.
        Supports the optional '-dry-run' flag as the first argument. Shows what the script would do without executing the action.

    ${0##*/} pull /sdcard/Pictures <destination>
        Copies all images from the phone to the specified folder on your computer (default: $HOME/Pictures/PhotoSync).
        Supports the optional '-dry-run' attribute as the first argument. Shows what the script would do without executing the action.

    ${0##*/} fix-dates -f ~/Pictures/MyAlbum
        Fixes the creation and modification date of all photos in 'MyAlbum' when the filemane matches yyyyMMdd_HHmmss.jpg
        The -f argument defines the list of folders to be fixed.
        Optionally, you can specify the batch size (-b) and the number of parallel jobs (-p).
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
    # Add a newline when progress reaches 100%
    if [ "$progress" -eq "$total" ]; then
        echo
    fi
}

init_connection() {

    # Ensure ADB is installed
    if ! which adb >/dev/null 2>&1; then
        throw_error '❌ adb is not on the $PATH'
    fi

    # Get device serial
    CONNECTED_DEVICES=("$(adb devices | grep '\t' | sed $'s/\t.*//')")
    SERIAL=''

    if [ ${#CONNECTED_DEVICES[@]} -eq 1 ]; then
        SERIAL="${CONNECTED_DEVICES[0]}"
    fi

    if [ -z "$SERIAL" ] ; then
        throw_error '❌ Check if your phone is connected. Ensure that no other device is connected at the same time.'
    fi

    DEVICE_BRAND="$(adb -s "$SERIAL" shell 'getprop ro.product.brand')"
    export DEVICE_ID="$SERIAL"

    echo "✅ $DEVICE_BRAND device with s/n $DEVICE_ID found"

    # exit 0

}
