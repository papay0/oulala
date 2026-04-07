#!/bin/bash
set -e

OULALA_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULTS_DIR="$OULALA_DIR/defaults"

echo "Updating Oulala..."

# Pull latest
cd "$OULALA_DIR" && git pull --quiet
echo "Pulled latest changes."

# Check each template file against the user's copy
for default_file in "$DEFAULTS_DIR"/*; do
  filename=$(basename "$default_file")
  user_file="$OULALA_DIR/$filename"

  if [ ! -f "$user_file" ]; then
    # User doesn't have this file yet — just copy it
    cp "$default_file" "$user_file"
    echo "New file: $filename"
  elif ! diff -q "$default_file" "$user_file" > /dev/null 2>&1; then
    # Files differ — use Claude to smart-merge
    echo "Merging updates into $filename..."
    claude -p "You are merging an updated template into a user's customized file.

TEMPLATE (new version from developers):
$(cat "$default_file")

USER'S VERSION (their customizations):
$(cat "$user_file")

Rules:
- Keep ALL of the user's customizations (name, personality, preferences, anything personal)
- Add any NEW sections or content from the template that the user doesn't have yet
- If the template improved wording of an existing section, use the improved version BUT keep the user's personal touches
- Do NOT remove anything the user added
- Output ONLY the merged file content, nothing else" > "$user_file.merged"

    mv "$user_file.merged" "$user_file"
    echo "Updated $filename (preserved your customizations)"
  fi
done

echo ""
echo "Oulala is up to date!"
echo "Start a new session to pick up changes."
