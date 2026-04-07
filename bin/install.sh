#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"
REPO_URL="https://github.com/papay0/oulala.git"

echo "Installing Oulala..."

# Install or update Claude Code
if command -v claude &> /dev/null; then
  echo "Updating Claude Code..."
  claude update -y 2>/dev/null || npm install -g @anthropic-ai/claude-code@latest 2>/dev/null || true
else
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code@latest
fi

# Clone or update Oulala
if [ -d "$OULALA_DIR" ]; then
  echo "Updating Oulala..."
  cd "$OULALA_DIR" && git pull --quiet
else
  echo "Cloning Oulala..."
  git clone --quiet "$REPO_URL" "$OULALA_DIR"
fi

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

# Start Oulala
cd "$OULALA_DIR"
if command -v caffeinate &> /dev/null; then
  caffeinate -s claude --dangerously-skip-permissions --name "Oulala" --remote-control
else
  claude --dangerously-skip-permissions --name "Oulala" --remote-control
fi
