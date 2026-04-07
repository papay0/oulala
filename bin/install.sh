#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"
MIN_VERSION="2.1.80"

echo "Installing Oulala..."

# Always install latest Claude Code
echo "Installing latest Claude Code..."
npm install -g @anthropic-ai/claude-code@latest

# Verify version
CLAUDE_VERSION=$(claude -v 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "Claude Code version: $CLAUDE_VERSION"

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
