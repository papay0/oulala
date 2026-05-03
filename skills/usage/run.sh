#!/usr/bin/env bash
# Read Claude subscription usage from Anthropic rate-limit headers.
# Outputs: two-line text bars for current session and weekly limit.

set -euo pipefail

CREDS="${CLAUDE_CREDENTIALS:-$HOME/.claude/.credentials.json}"

if [[ ! -f "$CREDS" ]]; then
  echo "no Claude credentials found at $CREDS — log in with the claude CLI first" >&2
  exit 1
fi

TOKEN=$(python3 -c "
import json, sys
d = json.load(open('$CREDS'))
print(d.get('claudeAiOauth', {}).get('accessToken', ''))
")

if [[ -z "$TOKEN" ]]; then
  echo "no claudeAiOauth.accessToken in $CREDS" >&2
  exit 1
fi

HEADERS=$(mktemp)
trap 'rm -f "$HEADERS"' EXIT

curl -sS -D "$HEADERS" -X POST "https://api.anthropic.com/v1/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"x"}]}' \
  -o /dev/null

python3 - "$HEADERS" <<'PY'
import re, sys, time

h = open(sys.argv[1]).read()

def grab(name):
    m = re.search(rf'^{re.escape(name)}:\s*(.+?)\r?$', h, re.M | re.I)
    return m.group(1).strip() if m else None

s5_pct = float(grab('anthropic-ratelimit-unified-5h-utilization') or 0)
s5_reset = int(grab('anthropic-ratelimit-unified-5h-reset') or 0)
s7_pct = float(grab('anthropic-ratelimit-unified-7d-utilization') or 0)
s7_reset = int(grab('anthropic-ratelimit-unified-7d-reset') or 0)

def fmt_until(ts):
    if not ts:
        return "?"
    delta = ts - int(time.time())
    if delta <= 0:
        return "now"
    if delta < 24 * 3600:
        h, rem = divmod(delta, 3600)
        m = rem // 60
        return f"in {h}h {m}m"
    when = time.localtime(ts)
    return time.strftime("%a %-I:%M %p", when)

def bar(p, width=10):
    f = max(0, min(width, int(round(p * width))))
    return "█" * f + "░" * (width - f)

print("Current session")
print(f"{bar(s5_pct)} {s5_pct*100:.0f}% used  ·  resets {fmt_until(s5_reset)}")
print()
print("Weekly limit")
print(f"{bar(s7_pct)} {s7_pct*100:.0f}% used  ·  resets {fmt_until(s7_reset)}")
PY
