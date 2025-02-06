#!/bin/bash

# Standardwerte setzen
batch_size=100
parallel_jobs=4
folders=()

# Argumente verarbeiten
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--batch) batch_size="$2"; shift 2 ;;
    -p|--parallel) parallel_jobs="$2"; shift 2 ;;
    -f|--folders) shift; while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do folders+=("$1"); shift; done ;;
    *) echo "Unbekannte Option: $1"; exit 1 ;;
  esac
done

# Prüfen, ob Ordner angegeben wurden
if [[ ${#folders[@]} -eq 0 ]]; then
  echo "❌ Keine Ordner angegeben!"
  exit 1
fi

process_file() {
  file="$1"
  datetime=$(basename "$file" | grep -oE '[0-9]{8}_[0-9]{6}' | sed 's/_/ /')

  if [ -z "$datetime" ]; then
    echo "⏭️ Überspringe ungültige Datei: $file" >&2
    return
  fi

  formatted_date=$(date -j -f "%Y%m%d %H%M%S" "$datetime" "+%m/%d/%Y %H:%M:%S")

  # Erstellungsdatum setzen
  SetFile -d "$formatted_date" "$file"

  # Änderungsdatum setzen
  touch -t "$(date -j -f "%Y%m%d %H%M%S" "$datetime" "+%Y%m%d%H%M.%S")" "$file"

}

export -f process_file

for folder in "${folders[@]}"; do
  if [ ! -d "$folder" ]; then
    echo "❌ Ordner nicht gefunden: $folder" >&2
    continue
  fi

  echo "🔍 Verarbeite Ordner: \"$folder\""

  find "$folder" -type f \( -iname "*.jpg" -o -iname "*.mp4" \) -print0 | 
    grep -zE '/[0-9]{8}_[0-9]{6}\.(jpg|mp4)$' | 
    xargs -0 -P "$parallel_jobs" -n "$batch_size" bash -c 'for file; do process_file "$file"; done' _

  find "$folder" -type f -name '._*' -exec rm {} \;
done
