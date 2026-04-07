#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"
MEMORY_DIR="$OULALA_DIR/memory"
INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ] || [ ! -f "$INPUT_FILE" ]; then
  echo "Usage: ./bin/sync-import.sh <file>"
  echo "Pass a file containing the exported memories."
  exit 1
fi

INCOMING=$(cat "$INPUT_FILE")
mkdir -p "$MEMORY_DIR"

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
- For .env, keep all keys from both. If a key has a value on one side and is empty on the other, KEEP THE VALUE. Only override if both sides have different non-empty values (prefer incoming in that case).

Output the merged result with each file separated by a line starting with '# FILE:':

# FILE: SOUL.md
(content)

# FILE: .env
(content)

# FILE: memory/MEMORY.md
(content)

# FILE: memory/YYYY-MM-DD.md
(for each daily note)

Output ONLY the merged files, nothing else.")

CURRENT_FILE=""
CURRENT_CONTENT=""

while IFS= read -r line; do
  if [[ "$line" =~ ^#\ FILE:\ (.+)$ ]]; then
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

if [ -n "$CURRENT_FILE" ]; then
  FILEPATH="$OULALA_DIR/$CURRENT_FILE"
  mkdir -p "$(dirname "$FILEPATH")"
  echo "$CURRENT_CONTENT" > "$FILEPATH"
  echo "Updated: $CURRENT_FILE"
fi

rm -f "$INPUT_FILE"
echo "Sync complete."
