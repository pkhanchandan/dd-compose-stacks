#!/usr/bin/env bash
# Sets "PreferredGUI": "v2" in Docker Desktop's settings-store.json.
# A backup of the original is saved once, so restore-docker-gui.sh can undo this.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

command -v jq >/dev/null || { echo "jq is required: https://jqlang.org/download/"; exit 1; }

mkdir -p "$DIR"

# Only back up once, so re-running never overwrites the true original
if [ ! -e "$BACKUP" ] && [ ! -e "$ABSENT_MARKER" ]; then
  if [ -f "$FILE" ]; then
    cp -p "$FILE" "$BACKUP"
    echo "Backed up original to: $BACKUP"
  else
    touch "$ABSENT_MARKER"
    echo '{}' > "$FILE"
    echo "No settings file existed; created a new one."
  fi
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
jq '. + {"PreferredGUI": "v2"}' "$FILE" > "$tmp"
cat "$tmp" > "$FILE"   # overwrite in place so permissions are preserved

# jq prints nothing (and succeeds) on an empty file, so verify the result.
# tr strips the \r that jq on Windows adds to its output.
if [ "$(jq -r '.PreferredGUI' "$FILE" | tr -d '\r')" != "v2" ]; then
  echo "Failed to set PreferredGUI in: $FILE"
  exit 1
fi

echo "Done. PreferredGUI is now: v2"
