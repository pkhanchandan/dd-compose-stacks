#!/usr/bin/env bash
# Restores Docker Desktop's settings-store.json to its state before set-docker-gui.sh ran.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ -f "$BACKUP" ]; then
  cat "$BACKUP" > "$FILE"   # overwrite in place so permissions are preserved
  rm "$BACKUP"
  echo "Restored original settings from backup."
elif [ -f "$ABSENT_MARKER" ]; then
  rm -f "$FILE" "$ABSENT_MARKER"
  echo "Settings file didn't exist originally; removed it."
else
  echo "No backup found at: $BACKUP"
  echo "Nothing to restore."
  exit 1
fi
