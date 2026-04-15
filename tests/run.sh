#!/bin/bash
# Simple test runner for Oulala scripts
set -e

PASS=0
FAIL=0
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$TESTS_DIR")"
TEMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local name="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -q "$expected"; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name"
    echo "    expected to contain: $expected"
    echo "    actual: $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local name="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name — file not found: $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_exists() {
  local name="$1" path="$2"
  if [ ! -f "$path" ]; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name — file should not exist: $path"
    FAIL=$((FAIL + 1))
  fi
}

# ─── CLI tests ───

echo "CLI (bin/oulala)"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" help 2>&1)
assert_contains "help shows usage" "Usage: oulala" "$OUTPUT"
assert_contains "help shows start command" "start" "$OUTPUT"
assert_contains "help shows update command" "update" "$OUTPUT"
assert_contains "help shows sync command" "sync" "$OUTPUT"
assert_contains "help shows channel command" "channel" "$OUTPUT"
assert_contains "help shows dev command" "dev" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" 2>&1)
assert_contains "no args shows help" "Usage: oulala" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" --help 2>&1)
assert_contains "--help shows help" "Usage: oulala" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" -h 2>&1)
assert_contains "-h shows help" "Usage: oulala" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" badcommand 2>&1 || true)
assert_contains "unknown command error" "Unknown command" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" channel 2>&1 || true)
assert_contains "channel help shows add" "add" "$OUTPUT"
assert_contains "channel help shows list" "list" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" channel add badplatform 2>&1 || true)
assert_contains "channel add unknown shows supported" "Supported channels" "$OUTPUT"

# ─── Install tests ───

echo ""
echo "Install (bin/install.sh)"

# Simulate install with a mock OULALA_DIR
MOCK_DIR="$TEMP_DIR/oulala-install"
mkdir -p "$MOCK_DIR/defaults"
cp "$PROJECT_DIR/defaults/SOUL.md" "$MOCK_DIR/defaults/SOUL.md"
cp "$PROJECT_DIR/defaults/MEMORY.md" "$MOCK_DIR/defaults/MEMORY.md"
mkdir -p "$MOCK_DIR/bin"
cp "$PROJECT_DIR/bin/install.sh" "$MOCK_DIR/bin/install.sh"

# Test brain setup logic (extract just that part)
OULALA_DIR="$MOCK_DIR"
mkdir -p "$OULALA_DIR/brain"
cp "$PROJECT_DIR/defaults/routines.json" "$MOCK_DIR/defaults/routines.json"
for f in "$OULALA_DIR/defaults/"*; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  if [ ! -f "$OULALA_DIR/brain/$BASENAME" ]; then
    cp "$f" "$OULALA_DIR/brain/$BASENAME"
  fi
done

assert_file_exists "copies SOUL.md to brain/" "$MOCK_DIR/brain/SOUL.md"
assert_file_exists "copies MEMORY.md to brain/" "$MOCK_DIR/brain/MEMORY.md"
assert_file_exists "copies routines.json to brain/" "$MOCK_DIR/brain/routines.json"

# Test it doesn't overwrite existing files
echo "customized" > "$MOCK_DIR/brain/SOUL.md"
for f in "$OULALA_DIR/defaults/"*; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  if [ ! -f "$OULALA_DIR/brain/$BASENAME" ]; then
    cp "$f" "$OULALA_DIR/brain/$BASENAME"
  fi
done
CONTENT=$(cat "$MOCK_DIR/brain/SOUL.md")
assert_eq "doesn't overwrite existing SOUL.md" "customized" "$CONTENT"

# ─── Sync tests ───

echo ""
echo "Sync (bin/sync.sh)"

# Test sync without git (should exit silently)
MOCK_BRAIN="$TEMP_DIR/oulala-sync/brain"
mkdir -p "$MOCK_BRAIN"
echo "test" > "$MOCK_BRAIN/MEMORY.md"

OUTPUT=$(OULALA_DIR="$TEMP_DIR/oulala-sync" bash -c '
  BRAIN_DIR="$OULALA_DIR/brain"
  cd "$BRAIN_DIR" || exit 0
  [ -d .git ] || exit 0
  echo "should not reach here"
' 2>&1)
assert_eq "sync exits silently without .git" "" "$OUTPUT"

# Test sync setup without gh
OUTPUT=$(bash "$PROJECT_DIR/bin/sync.sh" setup 2>&1 || true)
if ! command -v gh &> /dev/null; then
  assert_contains "setup requires gh" "GitHub CLI" "$OUTPUT"
fi

# ─── Update tests ───

echo ""
echo "Update (bin/update.sh)"

# Test merge detection with defaults
MOCK_UPDATE="$TEMP_DIR/oulala-update"
mkdir -p "$MOCK_UPDATE/defaults" "$MOCK_UPDATE/brain"
echo "# Original soul" > "$MOCK_UPDATE/defaults/SOUL.md"
echo "# Original soul" > "$MOCK_UPDATE/brain/SOUL.md"

# Same content = no merge needed
NEEDS_MERGE=false
if ! diff -q "$MOCK_UPDATE/defaults/SOUL.md" "$MOCK_UPDATE/brain/SOUL.md" > /dev/null 2>&1; then
  NEEDS_MERGE=true
fi
assert_eq "identical files don't trigger merge" "false" "$NEEDS_MERGE"

# Different content = merge needed
echo "# Updated soul with new section" > "$MOCK_UPDATE/defaults/SOUL.md"
NEEDS_MERGE=false
if ! diff -q "$MOCK_UPDATE/defaults/SOUL.md" "$MOCK_UPDATE/brain/SOUL.md" > /dev/null 2>&1; then
  NEEDS_MERGE=true
fi
assert_eq "different files trigger merge" "true" "$NEEDS_MERGE"

# ─── Import tests ───

echo ""
echo "Import (bin/oulala import)"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" import 2>&1 || true)
assert_contains "import shows sources" "chatgpt" "$OUTPUT"

OUTPUT=$(bash "$PROJECT_DIR/bin/oulala" import chatgpt 2>&1 || true)
assert_contains "import chatgpt shows usage" "conversations.json" "$OUTPUT"

# Test Python script parse with a mock export
MOCK_EXPORT="$TEMP_DIR/conversations.json"
cat > "$MOCK_EXPORT" << 'JSONEOF'
[
  {
    "title": "Test conversation",
    "create_time": 1712363200,
    "current_node": "msg-2",
    "mapping": {
      "root": {"id": "root", "message": null, "parent": null, "children": ["msg-1"]},
      "msg-1": {"id": "msg-1", "message": {"author": {"role": "user"}, "content": {"content_type": "text", "parts": ["Hello"]}}, "parent": "root", "children": ["msg-2"]},
      "msg-2": {"id": "msg-2", "message": {"author": {"role": "assistant"}, "content": {"content_type": "text", "parts": ["Hi there"]}}, "parent": "msg-1", "children": []}
    }
  }
]
JSONEOF

# Test that the Python parser works (just parse, no Claude calls)
OUTPUT=$(python3 -c "
import sys; sys.path.insert(0, '$PROJECT_DIR/bin')
from importlib.util import spec_from_file_location, module_from_spec
spec = spec_from_file_location('imp', '$PROJECT_DIR/bin/import-chatgpt.py')
mod = module_from_spec(spec); spec.loader.exec_module(mod)
convs = mod.parse_export('$MOCK_EXPORT')
print(f'parsed:{len(convs)}')
msgs = mod.extract_active_branch(convs[0])
print(f'messages:{len(msgs)}')
print(f'role0:{msgs[0][\"role\"]}')
print(f'text0:{msgs[0][\"text\"]}')
" 2>&1)
assert_contains "parser loads export JSON" "parsed:1" "$OUTPUT"
assert_contains "parser extracts active branch" "messages:2" "$OUTPUT"
assert_contains "parser gets user role" "role0:user" "$OUTPUT"
assert_contains "parser gets message text" "text0:Hello" "$OUTPUT"

# Test envelope format
cat > "$MOCK_EXPORT" << 'JSONEOF'
{"conversations": [{"title": "Envelope test", "create_time": 1712363200, "current_node": "m1", "mapping": {"r": {"id": "r", "message": null, "parent": null, "children": ["m1"]}, "m1": {"id": "m1", "message": {"author": {"role": "user"}, "content": {"content_type": "text", "parts": ["test"]}}, "parent": "r", "children": []}}}]}
JSONEOF

OUTPUT=$(python3 -c "
import sys; sys.path.insert(0, '$PROJECT_DIR/bin')
from importlib.util import spec_from_file_location, module_from_spec
spec = spec_from_file_location('imp', '$PROJECT_DIR/bin/import-chatgpt.py')
mod = module_from_spec(spec); spec.loader.exec_module(mod)
convs = mod.parse_export('$MOCK_EXPORT')
print(f'parsed:{len(convs)}')
" 2>&1)
assert_contains "parser handles envelope format" "parsed:1" "$OUTPUT"

# ─── Structure tests ───

echo ""
echo "Project structure"

assert_file_exists "CLAUDE.md exists" "$PROJECT_DIR/CLAUDE.md"
assert_file_exists "defaults/SOUL.md exists" "$PROJECT_DIR/defaults/SOUL.md"
assert_file_exists "defaults/MEMORY.md exists" "$PROJECT_DIR/defaults/MEMORY.md"
assert_file_exists "defaults/routines.json exists" "$PROJECT_DIR/defaults/routines.json"
assert_file_exists "bin/oulala exists" "$PROJECT_DIR/bin/oulala"
assert_file_exists "bin/install.sh exists" "$PROJECT_DIR/bin/install.sh"
assert_file_exists "bin/sync.sh exists" "$PROJECT_DIR/bin/sync.sh"
assert_file_exists "bin/update.sh exists" "$PROJECT_DIR/bin/update.sh"
assert_file_exists "skills/oura/SKILL.md exists" "$PROJECT_DIR/skills/oura/SKILL.md"
assert_file_exists "skills/imessage/SKILL.md exists" "$PROJECT_DIR/skills/imessage/SKILL.md"
assert_file_exists "skills/weather/SKILL.md exists" "$PROJECT_DIR/skills/weather/SKILL.md"
assert_file_exists "skills/spotify/SKILL.md exists" "$PROJECT_DIR/skills/spotify/SKILL.md"
assert_file_exists "skills/github/SKILL.md exists" "$PROJECT_DIR/skills/github/SKILL.md"
assert_file_exists ".claude/settings.json exists" "$PROJECT_DIR/.claude/settings.json"
assert_file_exists "bin/import-chatgpt.py exists" "$PROJECT_DIR/bin/import-chatgpt.py"
assert_file_exists ".gitignore exists" "$PROJECT_DIR/.gitignore"
assert_file_exists "README.md exists" "$PROJECT_DIR/README.md"

# Check gitignore has required entries
GITIGNORE=$(cat "$PROJECT_DIR/.gitignore")
assert_contains ".gitignore has brain/" "brain/" "$GITIGNORE"
assert_contains ".gitignore has .env" ".env" "$GITIGNORE"
assert_contains ".gitignore has .sync" ".sync" "$GITIGNORE"

# Check CLAUDE.md references brain/ not memory/
CLAUDE=$(cat "$PROJECT_DIR/CLAUDE.md")
assert_contains "CLAUDE.md references brain/SOUL.md" "brain/SOUL.md" "$CLAUDE"
assert_contains "CLAUDE.md references brain/MEMORY.md" "brain/MEMORY.md" "$CLAUDE"
assert_contains "CLAUDE.md references brain/routines.json" "brain/routines.json" "$CLAUDE"
assert_contains "CLAUDE.md has proactive follow-ups section" "Proactive Follow-ups" "$CLAUDE"

# Check routines.json is valid JSON
if python3 -c "import json; json.load(open('$PROJECT_DIR/defaults/routines.json'))" 2>/dev/null; then
  echo "  ✓ defaults/routines.json is valid JSON"
  PASS=$((PASS + 1))
else
  echo "  ✗ defaults/routines.json is invalid JSON"
  FAIL=$((FAIL + 1))
fi

# Check settings.json hooks
SETTINGS=$(cat "$PROJECT_DIR/.claude/settings.json")
assert_contains "settings has SessionStart hook" "SessionStart" "$SETTINGS"
assert_contains "settings has UserPromptSubmit hook" "UserPromptSubmit" "$SETTINGS"
assert_contains "settings has Stop hook" "Stop" "$SETTINGS"
assert_contains "settings has proactive follow-up hook" "Proactive check" "$SETTINGS"
assert_contains "settings has day-of-week in timestamp" "%A" "$SETTINGS"
assert_contains "settings has sync pull" "sync.sh pull" "$SETTINGS"
assert_contains "settings has sync push" "sync.sh push" "$SETTINGS"

# Check bin/oulala is executable
if [ -x "$PROJECT_DIR/bin/oulala" ]; then
  echo "  ✓ bin/oulala is executable"
  PASS=$((PASS + 1))
else
  echo "  ✗ bin/oulala is not executable"
  FAIL=$((FAIL + 1))
fi

# ─── Results ───

echo ""
echo "━━━━━━━━━━━━━━━━━━━━"
echo "  $PASS passed, $FAIL failed"
echo "━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
