#!/bin/bash

# Set source and destination directories
SRC_DIR="/sdcard/Pictures"
DEST_DIR="$HOME/Pictures/PhoneSync"

# Ensure ADB is running
adb devices | grep -q "device$" || { echo "📱 No device found"; exit 1; }

# Get device serial
FOUND_SERIALS=("$(adb devices | grep '\t' | sed $'s/\t.*//')")
DEVICE=''

if [ ${#FOUND_SERIALS[@]} -eq 1 ]; then
    DEVICE="${FOUND_SERIALS[0]}"
fi

if [ -z "$DEVICE" ] ; then
    echo '❌ Check if your phone is connected. Ensure that no other device is connected at the same time.'
    exit 1
fi

# Ensure device stays awake during transfer
adb -s "$DEVICE" shell settings put global stay_on_while_plugged_in 3
trap 'adb -s "$DEVICE" shell settings put global stay_on_while_plugged_in 0' EXIT # Restore original stay awake setting

# Sync each file while preserving folder structure
FILES=$(adb -s "$DEVICE" shell "find '$SRC_DIR' -type f ! -path '*/.*' \( -iname '*.jpg' -o -iname '*.mp4' \)" | tr -d '\r')

while IFS= read -r FILE; do
    REL_PATH=${FILE#"$SRC_DIR/"}  # Remove the base path
    LOCAL_PATH="$DEST_DIR/$REL_PATH"
    
    # Skip file if it already exists locally with the same size
    if [ -f "$LOCAL_PATH" ]; then
        echo "⏭️ Skipping already transferred file: $REL_PATH"
    else

        # Create the local directory if it doesn't exist
        mkdir -p "$(dirname "$LOCAL_PATH")"
        
        # Pull the file
        if ! adb -s "$DEVICE" pull -q "$FILE" "$LOCAL_PATH"; then
            echo "❌ Error pulling file: $FILE" >&2
            continue  # Skip this file on error and continue with next
        fi

    fi

done <<< "$FILES"
