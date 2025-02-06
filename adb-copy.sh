#!/bin/bash

# Author: rbxrt
# License: MIT

copy_to_phone() {

    init_connection

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

    # Target directory on Android
    DEST_PATH="${!#}"
    # Check if destination is writable
    T="$(adb -s $DEVICE_ID shell "[[ -d \"$DEST_PATH\" ]] && echo YES || echo NO")"

    if [ "$T" == 'NO' ]; then
        throw_error '❌ Destination is not a writable directory.'
    fi

    # All arguments except the last are source directories
    SOURCE_DIRS=("${@:1:$#-1}")
    for i in "${!SOURCE_DIRS[@]}"; do
        SOURCE_DIRS[$i]="${SOURCE_DIRS[$i]%/}" # Remove trailing slash
    done

    echo "⏳ Copying Computer:$SOURCE_DIRS → Phone:$DEST_PATH"


    # Ensure device stays awake during transfer
    adb -s "$DEVICE_ID" shell settings put global stay_on_while_plugged_in 3

    # Create temp file for sorting files by modification time
    TEMP_FILE=$(mktemp)

    # Finish actions
    trap 'adb -s "$DEVICE_ID" shell settings put global stay_on_while_plugged_in 0; rm -f "$TEMP_FILE"' EXIT # Ensure cleanup on exit

    # Collect all eligible files
    for DIR in "${SOURCE_DIRS[@]}"; do
        if [ -d "$DIR" ]; then
            find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.mp4" -o -iname '*.gif' \) ! -name "._*" ! -name "*~" -exec stat -f "%m %N" {} + >> "$TEMP_FILE"
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
                echo "Would pull: $SRC → $TARGET_FILE"
            else

            (
                # Create directory structure on Android
                adb -s "$DEVICE_ID" shell "mkdir -p \"$TARGET_DIR/\""

                # Copy file to Android
                adb -s "$DEVICE_ID" push -q "$SRC" "$TARGET_FILE"

                # Copy compressed file to Android (might be slower)
                # tar czf - -C "$(dirname "$SRC")" "$(basename "$SRC")" | adb -s "$DEVICE_ID" shell "mkdir -p \"$TARGET_DIR/\" && tar xzf - -C \"$TARGET_DIR/\""

                # Notify Media Scanner
                adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://'$TARGET_FILE'" >/dev/null

            ) < /dev/null

                progress_bar "$NUM" "$FILE_COUNT"
            fi

        else
            throw_error "❌ Source file \"$SRC\" does not exist or is not accessible."
        fi
    done <<< "$SORTED_FILES"

    exit 0
}
