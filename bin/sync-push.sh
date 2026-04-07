#!/bin/bash
# Auto-sync brain/ to GitHub. Called by Stop hook after each conversation.
# Uses git merge first, falls back to AI merge on conflict.

BRAIN_DIR="$HOME/.oulala/brain"

cd "$BRAIN_DIR" || exit 0
[ -d .git ] || exit 0

# Stage and commit local changes
git add -A
git diff --cached --quiet && exit 0
git commit -m "sync" --quiet

# Try git pull + rebase
if git pull --rebase --quiet 2>/dev/null; then
  git push --quiet
  exit 0
fi

# Rebase failed — there's a conflict. Use AI to resolve.
git rebase --abort 2>/dev/null

# Get the remote version of conflicted files
git fetch --quiet
CONFLICTS=$(git diff --name-only HEAD origin/main 2>/dev/null)

if [ -z "$CONFLICTS" ]; then
  git push --quiet 2>/dev/null
  exit 0
fi

# For each conflicted file, AI merge
for file in $CONFLICTS; do
  LOCAL=$(cat "$file" 2>/dev/null || echo "")
  REMOTE=$(git show "origin/main:$file" 2>/dev/null || echo "")

  if [ -n "$LOCAL" ] && [ -n "$REMOTE" ]; then
    MERGED=$(claude -p "Merge these two versions of $file. Keep ALL content from both. Never delete anything.

VERSION A (this device):
$LOCAL

VERSION B (other device):
$REMOTE

Output ONLY the merged content, nothing else." 2>/dev/null)

    if [ -n "$MERGED" ]; then
      echo "$MERGED" > "$file"
    fi
  fi
done

# Commit the AI-merged result and force push (we've incorporated both sides)
git add -A
git commit -m "ai-merged sync" --quiet 2>/dev/null
git push --force-with-lease --quiet 2>/dev/null
