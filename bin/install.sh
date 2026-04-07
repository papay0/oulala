#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"
REPO_URL="https://github.com/papay0/oulala.git"

echo "Installing Oulala..."

if [ -d "$OULALA_DIR" ]; then
  echo "Updating existing installation..."
  cd "$OULALA_DIR" && git pull --quiet
else
  echo "Cloning Oulala..."
  git clone --quiet "$REPO_URL" "$OULALA_DIR"
fi

# Copy SOUL.md from defaults on first install only — never overwrite user's version
if [ ! -f "$OULALA_DIR/SOUL.md" ]; then
  cp "$OULALA_DIR/defaults/SOUL.md" "$OULALA_DIR/SOUL.md"
  echo "Created SOUL.md — edit it to customize your AI's personality."
fi

# Copy .env.example if no .env exists
if [ ! -f "$OULALA_DIR/.env" ]; then
  cp "$OULALA_DIR/defaults/.env.example" "$OULALA_DIR/.env"
fi

echo ""
echo "Oulala is installed at $OULALA_DIR"
echo ""
echo "Next steps:"
echo "  1. Open the Claude Code app on your phone"
echo "  2. Connect to this machine"
echo "  3. Open ~/.oulala"
echo "  4. Start talking to your AI"
echo ""
echo "Edit ~/.oulala/SOUL.md to customize your AI's personality."
