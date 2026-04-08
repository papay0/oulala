#!/bin/bash
set -e

OULALA_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Updating Oulala..."

cd "$OULALA_DIR" && git pull --quiet
echo "Pulled latest changes."

# Migrate old structure → brain/ if needed
if [ ! -d "$OULALA_DIR/brain" ]; then
  mkdir -p "$OULALA_DIR/brain"
fi

if [ -f "$OULALA_DIR/SOUL.md" ] && [ ! -f "$OULALA_DIR/brain/SOUL.md" ]; then
  mv "$OULALA_DIR/SOUL.md" "$OULALA_DIR/brain/SOUL.md"
  echo "Migrated SOUL.md → brain/SOUL.md"
fi

if [ -d "$OULALA_DIR/memory" ] && [ "$(ls -A "$OULALA_DIR/memory" 2>/dev/null)" ]; then
  mv "$OULALA_DIR/memory/"* "$OULALA_DIR/brain/" 2>/dev/null
  rmdir "$OULALA_DIR/memory" 2>/dev/null
  echo "Migrated memory/ → brain/"
fi

# Smart-merge any updated defaults into brain/
for default_file in "$OULALA_DIR/defaults/"*.md; do
  [ -f "$default_file" ] || continue
  filename=$(basename "$default_file")
  user_file="$OULALA_DIR/brain/$filename"

  if [ ! -f "$user_file" ]; then
    cp "$default_file" "$user_file"
    echo "New file: brain/$filename"
  elif ! diff -q "$default_file" "$user_file" > /dev/null 2>&1; then
    echo "Merging updates into brain/$filename..."
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
    echo "Updated brain/$filename (preserved your customizations)"
  fi
done

# Ensure oulala is in PATH
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
if ! grep -q '.oulala/bin' "$SHELL_RC" 2>/dev/null; then
  echo 'export PATH="$HOME/.oulala/bin:$PATH"' >> "$SHELL_RC"
  echo "Added ~/.oulala/bin to PATH (run: source $SHELL_RC)"
fi

echo "Oulala is up to date!"
