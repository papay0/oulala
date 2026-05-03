---
name: tomorrow
description: Show what's coming tomorrow — calendar events, prep needed, anything time-sensitive. Use when the user asks "what's tomorrow" or hits /tomorrow.
---

# Tomorrow

Lighter-weight than `/today` — just pulls tomorrow's calendar plus any pending items that need same-day prep.

## What to gather

1. **Calendar** — tomorrow's events from `Google_Calendar.list_events` for tomorrow's local-day window. Order by start time.
2. **Prep needed** — for each event, infer if anything must be done tonight: travel time to first event, materials to print, person to call, food to pack. Keep this lightweight; only flag obvious cases.
3. **First-thing time** — surface the earliest "real" event prominently so the user can set an alarm if needed.

## Output format

```
📅 Tomorrow (Mon)
🌅 first thing: 8:30 — flight to Austin
• 9:00 — standup
• 11:00 — 1:1 with manager
🎯 Prep tonight
• pack carry-on
• Uber by 7:00 AM
```

If nothing tomorrow: "tomorrow's open 🌴".

## When NOT to use

- The user is asking about events further out (next week, etc.) — defer to a wider calendar query, not this skill.
- The current local time is before noon — they may mean "today" colloquially; if ambiguous, ask.
