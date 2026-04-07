#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"

echo "Installing Oulala..."

# Install latest Claude Code (official installer)
echo "Installing latest Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

echo "Claude Code version: $(claude -v 2>/dev/null)"

# Copy defaults on first install only
if [ ! -f "$OULALA_DIR/SOUL.md" ]; then
  cp "$OULALA_DIR/defaults/SOUL.md" "$OULALA_DIR/SOUL.md"
  echo "Created SOUL.md — edit it to customize your AI's personality."
fi

if [ ! -f "$OULALA_DIR/.env" ]; then
  cp "$OULALA_DIR/defaults/.env.example" "$OULALA_DIR/.env"
fi

echo ""
echo "Oulala is installed! Starting your assistant..."
echo ""

cd "$OULALA_DIR"

# Build launch flags
FLAGS="--name Oulala --remote-control"
if [ "$(id -u)" = "0" ]; then
  FLAGS="--permission-mode bypassPermissions $FLAGS"
else
  FLAGS="--dangerously-skip-permissions $FLAGS"
fi

# Prevent sleep on macOS
if command -v caffeinate &> /dev/null; then
  caffeinate -s claude $FLAGS
else
  claude $FLAGS
fi
