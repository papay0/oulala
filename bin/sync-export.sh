#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"
MEMORY_DIR="$OULALA_DIR/memory"
EXPORT=""

if [ -f "$OULALA_DIR/SOUL.md" ]; then
  EXPORT+="# SOUL.md"$'\n'
  EXPORT+="$(cat "$OULALA_DIR/SOUL.md")"$'\n\n'
fi

if [ -f "$OULALA_DIR/.env" ]; then
  EXPORT+="# .env"$'\n'
  EXPORT+="$(cat "$OULALA_DIR/.env")"$'\n\n'
fi

if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  EXPORT+="# memory/MEMORY.md"$'\n'
  EXPORT+="$(cat "$MEMORY_DIR/MEMORY.md")"$'\n\n'
fi

for f in "$MEMORY_DIR"/????-??-??.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  EXPORT+="# memory/$BASENAME"$'\n'
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
