#!/bin/bash
set -e

OULALA_DIR="$HOME/.oulala"

# Handle root
if [ "$(id -u)" = "0" ]; then
  echo "Oulala can't run as root (Claude Code restriction)."
  echo "I can create an 'oulala' user and install there."
  echo ""
  read -p "Create user 'oulala' and continue? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if ! id -u oulala &>/dev/null; then
      useradd -m -s /bin/bash oulala
      echo "Created user 'oulala'"
    fi
    if [ -f /root/.ssh/authorized_keys ]; then
      mkdir -p /home/oulala/.ssh
      cp /root/.ssh/authorized_keys /home/oulala/.ssh/authorized_keys
      chown -R oulala:oulala /home/oulala/.ssh
      chmod 700 /home/oulala/.ssh
      echo "Copied SSH keys — you can SSH in as: ssh oulala@$(hostname -I | awk '{print $1}')"
    fi
    echo "Switching to 'oulala' user and installing..."
    exec su - oulala -c "curl -sL oulala-ai.vercel.app/install | bash"
  else
    echo "To install manually:"
    echo "  adduser oulala"
    echo "  su - oulala"
    echo "  curl -sL oulala-ai.vercel.app/install | bash"
    exit 1
  fi
fi

echo "Installing Oulala..."

# Install latest Claude Code
echo "Installing latest Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

echo "Claude Code version: $(claude -v 2>/dev/null)"

# Set up brain/ from defaults on first install
mkdir -p "$OULALA_DIR/brain"
for f in "$OULALA_DIR/defaults/"*.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  if [ ! -f "$OULALA_DIR/brain/$BASENAME" ]; then
    cp "$f" "$OULALA_DIR/brain/$BASENAME"
    echo "Created brain/$BASENAME"
  fi
done

# Create .env
if [ ! -f "$OULALA_DIR/.env" ]; then
  touch "$OULALA_DIR/.env"
fi

echo ""
echo "Oulala is installed! Starting your assistant..."
echo "Edit ~/.oulala/brain/SOUL.md to customize your AI's personality."
echo ""

cd "$OULALA_DIR"
if command -v caffeinate &> /dev/null; then
  caffeinate -s claude --dangerously-skip-permissions --name "Oulala" --remote-control
else
  claude --dangerously-skip-permissions --name "Oulala" --remote-control
fi
