#!/bin/bash
# Oulala brain sync. Usage:
#   sync.sh setup    — create or connect to private brain repo
#   sync.sh pull     — pull latest from brain repo
#   sync.sh push     — push local changes to brain repo

BRAIN_DIR="$HOME/.oulala/brain"
CONFIG_FILE="$HOME/.oulala/.sync"
ACTION="${1:-push}"

ai_merge() {
  local file="$1"
  local local_content=$(cat "$file" 2>/dev/null || echo "")
  local remote_content=$(git show "origin/main:$file" 2>/dev/null || echo "")

  [ -z "$local_content" ] || [ -z "$remote_content" ] && return

  local merged=$(claude --dangerously-skip-permissions -p "Merge these two versions of $file. Keep ALL content from both. Never delete anything.

VERSION A (this device):
$local_content

VERSION B (other device):
$remote_content

Output ONLY the merged content, nothing else." 2>/dev/null)

  [ -n "$merged" ] && echo "$merged" > "$file"
}

git_sync() {
  local direction="$1"

  cd "$BRAIN_DIR" || exit 0
  [ -d .git ] || exit 0

  git add -A
  git diff --cached --quiet || git commit -m "sync" --quiet

  if git pull --rebase --quiet 2>/dev/null; then
    [ "$direction" = "push" ] && git push --quiet 2>/dev/null
    exit 0
  fi

  # Rebase failed — AI merge
  git rebase --abort 2>/dev/null
  git fetch --quiet

  for file in $(git diff --name-only HEAD origin/main 2>/dev/null); do
    ai_merge "$file"
  done

  git add -A
  git commit -m "ai-merged sync" --quiet 2>/dev/null
  [ "$direction" = "push" ] && git push --force-with-lease --quiet 2>/dev/null
}

do_setup() {
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
    # Repo exists — connect to it
    echo "Found existing brain repo: $REPO_FULL"
    if [ -d "$BRAIN_DIR" ]; then
      if [ "$(ls -A "$BRAIN_DIR" 2>/dev/null)" ]; then
        mv "$BRAIN_DIR" "$BRAIN_DIR.backup.$(date +%s)"
        echo "Backed up existing brain/"
      else
        rmdir "$BRAIN_DIR"
      fi
    fi
    gh repo clone "$REPO_FULL" "$BRAIN_DIR" -- --quiet
  else
    # Create new repo
    echo "Creating private repo $REPO_FULL..."
    gh repo create "oulala-brain" --private
    cd "$BRAIN_DIR"
    git init --quiet
    git remote add origin "https://github.com/$REPO_FULL.git"
    gh auth setup-git 2>/dev/null || true
    git add -A
    git diff --cached --quiet || git commit -m "initial sync" --quiet
    git push -u origin HEAD:main --quiet 2>/dev/null || git push -u origin main --quiet
  fi

  echo "$REPO_FULL" > "$CONFIG_FILE"
  echo "Sync is set up! Memories auto-sync to: github.com/$REPO_FULL (private)"
}

case "$ACTION" in
  setup) do_setup ;;
  pull)  git_sync pull ;;
  push)  git_sync push ;;
  *)     echo "Usage: sync.sh [setup|pull|push]" ;;
esac
