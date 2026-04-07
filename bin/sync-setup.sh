#!/bin/bash
set -e

BRAIN_DIR="$HOME/.oulala/brain"
CONFIG_FILE="$HOME/.oulala/.sync"

if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is required: https://cli.github.com"
  exit 1
fi

if ! gh auth status &> /dev/null 2>&1; then
  echo "Please log in first: gh auth login"
  exit 1
fi

if [ -f "$CONFIG_FILE" ]; then
  echo "Sync already set up: $(cat "$CONFIG_FILE")"
  exit 0
fi

GH_USER=$(gh api user --jq '.login')
REPO_FULL="$GH_USER/oulala-brain"

if gh repo view "$REPO_FULL" &> /dev/null 2>&1; then
  # Repo exists — check if it has content (another device already set up)
  REMOTE_COMMITS=$(gh api "repos/$REPO_FULL/commits" --jq 'length' 2>/dev/null || echo "0")
  if [ "$REMOTE_COMMITS" != "0" ] && [ "$REMOTE_COMMITS" != "" ]; then
    echo "Brain repo already has content from another device."
    echo "Use 'connect my brain' instead to pull those memories."
    exit 0
  fi
else
  echo "Creating private repo $REPO_FULL..."
  gh repo create "oulala-brain" --private
fi

cd "$BRAIN_DIR"
if [ ! -d ".git" ]; then
  git init --quiet
  git remote add origin "https://github.com/$REPO_FULL.git"
  gh auth setup-git 2>/dev/null || true
fi

git add -A
git diff --cached --quiet || git commit -m "initial sync" --quiet
git push -u origin HEAD:main --quiet 2>/dev/null || git push -u origin main --quiet

echo "$REPO_FULL" > "$CONFIG_FILE"
echo "Sync is set up! Memories auto-sync to: github.com/$REPO_FULL (private)"
