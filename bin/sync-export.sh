#!/bin/bash
set -e

BRAIN_DIR="$HOME/.oulala/brain"
EXPORT=""

for f in "$BRAIN_DIR"/*.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  EXPORT+="# $BASENAME"$'\n'
  EXPORT+="$(cat "$f")"$'\n\n'
done

if command -v pbcopy &> /dev/null; then
  echo "$EXPORT" | pbcopy
  echo "Copied to clipboard."
elif command -v xclip &> /dev/null; then
  echo "$EXPORT" | xclip -selection clipboard
  echo "Copied to clipboard."
else
  echo "$EXPORT"
fi
