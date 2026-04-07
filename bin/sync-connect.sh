#!/bin/bash
set -e

BRAIN_DIR="$HOME/.oulala/brain"
CONFIG_FILE="$HOME/.oulala/.sync"

if [ -f "$CONFIG_FILE" ]; then
  echo "Already connected to: $(cat "$CONFIG_FILE")"
  exit 0
fi

# Check gh
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is required. Install it: https://cli.github.com"
  exit 1
fi

GH_USER=$(gh api user --jq '.login')
REPO_NAME="oulala-brain"
REPO_FULL="$GH_USER/$REPO_NAME"

# Check if brain repo exists
if ! gh repo view "$REPO_FULL" &> /dev/null 2>&1; then
  echo "No brain repo found at $REPO_FULL"
  echo "Run sync setup on your main device first, or specify a repo:"
  echo "  ./bin/sync-connect.sh username/repo-name"
  exit 1
fi

# Use custom repo if provided
if [ -n "$1" ]; then
  REPO_FULL="$1"
fi

echo "Connecting to brain repo: $REPO_FULL..."

# Back up existing brain/ just in case
if [ -d "$BRAIN_DIR" ]; then
  if [ "$(ls -A "$BRAIN_DIR" 2>/dev/null)" ]; then
    BACKUP="$BRAIN_DIR.backup.$(date +%s)"
    mv "$BRAIN_DIR" "$BACKUP"
    echo "Backed up existing brain/"
  else
    rmdir "$BRAIN_DIR"
  fi
fi

# Clone brain repo
gh repo clone "$REPO_FULL" "$BRAIN_DIR" -- --quiet

# Save config
echo "$REPO_FULL" > "$CONFIG_FILE"

echo "Connected! Your memories are synced."
