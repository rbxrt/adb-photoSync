#!/bin/bash

# Author: rbxrt
# License: MIT

copy_to_computer() {

    init_connection

    # Check if first argument is -dry-run
    DRY_RUN=false
    if [ "$1" == "-dry-run" ]; then
        DRY_RUN=true
        shift  # Remove the flag from the arguments
    fi

    # Set source and destination directories
    SRC_DIR=${1:-/sdcard/DCIM}
    DEST_DIR=${2:-$HOME/Pictures/PhotoSync}

    echo "$SRC_DIR, $DEST_DIR, (dry run: $DRY_RUN)"

    # Ensure device stays awake during transfer
    adb -s "$DEVICE_ID" shell settings put global stay_on_while_plugged_in 3
    trap 'adb -s "$DEVICE_ID" shell settings put global stay_on_while_plugged_in 0' EXIT # Restore original stay awake setting

    # Sync each file while preserving folder structure
    FILES=$(adb -s "$DEVICE_ID" shell "find '$SRC_DIR' -type f ! -path '*/.*' \( -iname '*.jpg' -o -iname '*.mp4' -o -iname '*.gif' \)" | tr -d '\r')

    # Progress
    FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
    NUM=0  # Initialize index

    while IFS= read -r FILE; do
        REL_PATH=${FILE#"$SRC_DIR/"}  # Remove the base path
        LOCAL_PATH="$DEST_DIR/$REL_PATH"
        NUM=$(( $NUM + 1 ))

        if $DRY_RUN; then
            # Skip when dry-run is active
            echo "Would push: $FILE → $LOCAL_PATH"
        elif [ -f "$LOCAL_PATH" ]; then
            # Skip file if it already exists locally with the same size
            echo "⏭️ Skipping already transferred file: $REL_PATH"
        else
            # Create the local directory if it doesn't exist
            mkdir -p "$(dirname "$LOCAL_PATH")"

            # Pull the file
            if ! adb -s "$DEVICE_ID" pull -q "$FILE" "$LOCAL_PATH"; then
                echo "❌ Error pulling file: $FILE" >&2
                continue  # Skip this file on error and continue with next
            fi

            progress_bar "$NUM" "$FILE_COUNT"

        fi

    done <<< "$FILES"

    exit 0
}
