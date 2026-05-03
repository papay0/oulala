#!/usr/bin/env bash
# Sleep report: last night + 7-day + 30-day from Oura.

set -euo pipefail

if [[ -f .env ]]; then
  set -a; source .env; set +a
fi

if [[ -z "${OURA_TOKEN:-}" ]]; then
  echo "no OURA_TOKEN in .env — see skills/oura/SKILL.md for setup" >&2
  exit 1
fi

today=$(date +%F)
start_30=$(date -d "30 days ago" +%F 2>/dev/null || date -v-30d +%F)
start_60=$(date -d "60 days ago" +%F 2>/dev/null || date -v-60d +%F)

resp=$(curl -sS -H "Authorization: Bearer $OURA_TOKEN" \
  "https://api.ouraring.com/v2/usercollection/daily_sleep?start_date=${start_60}&end_date=${today}")

python3 - "$resp" "$today" <<'PY'
import json, sys
from datetime import date, timedelta

raw, today_str = sys.argv[1], sys.argv[2]
data = json.loads(raw).get("data", [])
by_day = {d["day"]: d for d in data}

today = date.fromisoformat(today_str)

def avg(days, key="score"):
    vals = [by_day[d.isoformat()][key] for d in days
            if d.isoformat() in by_day and by_day[d.isoformat()].get(key) is not None]
    return sum(vals) / len(vals) if vals else None

# last logged night (yesterday or today, whichever has data)
last_key = None
for offset in range(0, 4):
    d = (today - timedelta(days=offset)).isoformat()
    if d in by_day:
        last_key = d
        break

if not last_key:
    print("no recent Oura sleep data — ring synced?")
    sys.exit(0)

last = by_day[last_key]
contrib = last.get("contributors", {}) or {}

# windows
days_7  = [today - timedelta(days=i) for i in range(0, 7)]
days_14 = [today - timedelta(days=i) for i in range(7, 14)]
days_30 = [today - timedelta(days=i) for i in range(0, 30)]
days_60 = [today - timedelta(days=i) for i in range(30, 60)]

avg_7  = avg(days_7)
avg_14 = avg(days_14)
avg_30 = avg(days_30)
avg_60 = avg(days_60)

def fmt(v):
    return f"{v:.0f}" if v is not None else "—"

def delta(cur, prev):
    if cur is None or prev is None:
        return ""
    d = cur - prev
    sign = "+" if d > 0 else ""
    return f" ({sign}{d:.0f} vs prev)"

trend_arrow = "→"
if avg_7 is not None and avg_30 is not None:
    diff = avg_7 - avg_30
    if diff >= 3:
        trend_arrow = "↑"
    elif diff <= -3:
        trend_arrow = "↓"

print(f"Last night ({last_key})")
print(f"  score: {last.get('score', '—')}")
contrib_keys = [("deep_sleep","deep"), ("rem_sleep","REM"), ("restfulness","restfulness"), ("total_sleep","total")]
shown = [f"{label} {contrib[k]}" for k, label in contrib_keys if k in contrib and contrib[k] is not None]
if shown:
    print("  " + " · ".join(shown))
print()
print(f"7-day avg:  {fmt(avg_7)}{delta(avg_7, avg_14)}")
print(f"30-day avg: {fmt(avg_30)}{delta(avg_30, avg_60)}")
print(f"trend: {trend_arrow}  (7d vs 30d)")
PY
