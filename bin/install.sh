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

# Copy SOUL.md from defaults on first install only
if [ ! -f "$OULALA_DIR/SOUL.md" ]; then
  cp "$OULALA_DIR/defaults/SOUL.md" "$OULALA_DIR/SOUL.md"
  echo "Created SOUL.md — edit it to customize your AI's personality."
fi

# Copy .env if not exists
if [ ! -f "$OULALA_DIR/.env" ]; then
  cp "$OULALA_DIR/defaults/.env.example" "$OULALA_DIR/.env"
fi

echo ""
echo "Oulala is installed! Starting your assistant..."
echo ""

# Start Oulala
cd "$OULALA_DIR" && claude --dangerously-skip-permissions --name "Oulala" --remote-control
