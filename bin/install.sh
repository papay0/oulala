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
    # Create user if doesn't exist
    if ! id -u oulala &>/dev/null; then
      useradd -m -s /bin/bash oulala
      echo "Created user 'oulala'"
    fi
    # Copy SSH keys so user can SSH in directly
    if [ -f /root/.ssh/authorized_keys ]; then
      mkdir -p /home/oulala/.ssh
      cp /root/.ssh/authorized_keys /home/oulala/.ssh/authorized_keys
      chown -R oulala:oulala /home/oulala/.ssh
      chmod 700 /home/oulala/.ssh
      echo "Copied SSH keys — you can SSH in as: ssh oulala@$(hostname -I | awk '{print $1}')"
    fi
    # Run install as oulala user
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
