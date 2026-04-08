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
    exec su - oulala -c "curl -sL oulala.app/install | bash"
  else
    echo "To install manually:"
    echo "  adduser oulala"
    echo "  su - oulala"
    echo "  curl -sL oulala.app/install | bash"
    exit 1
  fi
fi

echo "Installing Oulala..."

# Install latest Claude Code
echo "Installing latest Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# Install Bun (required for channel plugins)
if ! command -v bun &> /dev/null; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Install tmux (keeps session alive)
if ! command -v tmux &> /dev/null; then
  echo "Installing tmux..."
  if command -v brew &> /dev/null; then
    brew install tmux
  elif command -v apt-get &> /dev/null; then
    sudo apt-get install -y tmux 2>/dev/null || echo "Could not install tmux — install it manually for persistent sessions."
  fi
fi

# Set up brain/ from defaults
mkdir -p "$OULALA_DIR/brain"
for f in "$OULALA_DIR/defaults/"*.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  if [ ! -f "$OULALA_DIR/brain/$BASENAME" ]; then
    cp "$f" "$OULALA_DIR/brain/$BASENAME"
    echo "Created brain/$BASENAME"
  fi
done

[ ! -f "$OULALA_DIR/.env" ] && touch "$OULALA_DIR/.env"

# Add oulala to PATH
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
if ! grep -q '.oulala/bin' "$SHELL_RC" 2>/dev/null; then
  echo 'export PATH="$HOME/.oulala/bin:$PATH"' >> "$SHELL_RC"
  echo "Added ~/.oulala/bin to PATH"
fi
export PATH="$OULALA_DIR/bin:$PATH"

echo ""
echo "Oulala is installed!"
echo "Edit ~/.oulala/brain/SOUL.md to customize your AI's personality."
echo ""
echo "Starting Oulala..."
echo ""

exec "$OULALA_DIR/bin/oulala" start
