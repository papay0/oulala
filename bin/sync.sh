#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"
MEMORY_DIR="$OULALA_DIR/memory"

echo "Oulala Sync"
echo ""
echo "  1) Export — copy memories to clipboard"
echo "  2) Import — paste memories from another device"
echo ""
read -p "Choose [1/2]: " choice

if [ "$choice" = "1" ]; then
  # Export: build one markdown blob and copy to clipboard
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

  # Include daily notes
  for f in "$MEMORY_DIR"/????-??-??.md; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    EXPORT+="# memory/$BASENAME"$'\n'
    EXPORT+="$(cat "$f")"$'\n\n'
  done

  # Copy to clipboard
  if command -v pbcopy &> /dev/null; then
    echo "$EXPORT" | pbcopy
  elif command -v xclip &> /dev/null; then
    echo "$EXPORT" | xclip -selection clipboard
  elif command -v xsel &> /dev/null; then
    echo "$EXPORT" | xsel --clipboard
  else
    echo "No clipboard tool found. Here's the export — copy it manually:"
    echo ""
    echo "$EXPORT"
    exit 0
  fi

  echo "Copied to clipboard. Paste it on your other device with: ./bin/sync.sh → option 2"

elif [ "$choice" = "2" ]; then
  # Import: read pasted content, use Claude to merge
  echo "Paste the exported memories below, then press Ctrl+D when done:"
  echo ""
  INCOMING=$(cat)

  mkdir -p "$MEMORY_DIR"

  # Build merge prompt
  EXISTING=""
  if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    EXISTING+="# Existing memory/MEMORY.md"$'\n'
    EXISTING+="$(cat "$MEMORY_DIR/MEMORY.md")"$'\n\n'
  fi

  for f in "$MEMORY_DIR"/????-??-??.md; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    EXISTING+="# Existing memory/$BASENAME"$'\n'
    EXISTING+="$(cat "$f")"$'\n\n'
  done

  if [ -f "$OULALA_DIR/SOUL.md" ]; then
    EXISTING+="# Existing SOUL.md"$'\n'
    EXISTING+="$(cat "$OULALA_DIR/SOUL.md")"$'\n\n'
  fi

  # Use Claude to merge
  MERGED=$(claude -p "You are merging memories from two devices of the same AI assistant.

EXISTING (this device):
$EXISTING

INCOMING (from another device):
$INCOMING

Rules:
- NEVER delete any memory or information from either side
- Merge both into a combined version
- If the same fact exists on both sides, keep the most detailed version
- For daily notes, keep all entries from both devices
- For SOUL.md, keep the most customized version
- For .env, keep all keys from both (incoming overrides if both have the same key)

Output the merged result in this exact format, with each file separated by a line starting with '# FILE:':

# FILE: SOUL.md
(merged soul content)

# FILE: .env
(merged env content)

# FILE: memory/MEMORY.md
(merged memory content)

# FILE: memory/YYYY-MM-DD.md
(for each daily note that exists)

Output ONLY the merged files, nothing else.")

  # Parse and write files
  CURRENT_FILE=""
  CURRENT_CONTENT=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ FILE:\ (.+)$ ]]; then
      # Write previous file if exists
      if [ -n "$CURRENT_FILE" ]; then
        FILEPATH="$OULALA_DIR/$CURRENT_FILE"
        mkdir -p "$(dirname "$FILEPATH")"
        echo "$CURRENT_CONTENT" > "$FILEPATH"
        echo "Updated: $CURRENT_FILE"
      fi
      CURRENT_FILE="${BASH_REMATCH[1]}"
      CURRENT_CONTENT=""
    else
      CURRENT_CONTENT+="$line"$'\n'
    fi
  done <<< "$MERGED"

  # Write last file
  if [ -n "$CURRENT_FILE" ]; then
    FILEPATH="$OULALA_DIR/$CURRENT_FILE"
    mkdir -p "$(dirname "$FILEPATH")"
    echo "$CURRENT_CONTENT" > "$FILEPATH"
    echo "Updated: $CURRENT_FILE"
  fi

  echo ""
  echo "Sync complete. Memories merged."

else
  echo "Invalid choice."
  exit 1
fi
