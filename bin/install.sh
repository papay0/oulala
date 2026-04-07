#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"

echo "Installing Oulala..."

# Install or update Claude Code
if command -v claude &> /dev/null; then
  echo "Updating Claude Code..."
  claude update --yes 2>/dev/null || claude update -y 2>/dev/null || npm install -g @anthropic-ai/claude-code@latest
else
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code@latest
fi

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
if command -v caffeinate &> /dev/null; then
  caffeinate -s claude --dangerously-skip-permissions --name "Oulala" --remote-control
else
  claude --dangerously-skip-permissions --name "Oulala" --remote-control
fi
