---
name: today
description: Show what's on today — calendar events, action-required emails, plus a one-line pulse on any active topics being tracked. Use when the user asks "what's on today" or hits /today.
---

# Today

Composes today's agenda from multiple sources. There's no shell script — this skill runs inside the agent because it needs MCP tool access (calendar, email).

## What to gather

1. **Calendar** — today's events from the user's primary calendar via `Google_Calendar.list_events` for the local-day window. Filter out all-day "context" events (vacations, OOO blocks) unless they're new today.
2. **Action-required emails** — `Gmail.search_threads` with `newer_than:14h is:unread`. Apply the same NOTIFY filter the urgent-email routine uses (recruiter scheduling, friends, legal/banking, anything URGENT). List sender + subject + 1-line ask.
3. **Active topics** *(optional)* — if `brain/MEMORY.md` exists, scan its index for entries marked active/in-progress. Mention only ones with same-day relevance (e.g. an open job decision, an upcoming interview today).

## Output format

Tight bullets, emoji-anchored, MarkdownV2 if rendering for Telegram:

```
📅 Today
• 9:00 — standup
• 14:00 — Apple interview
✉️ Action emails
• Recruiter <sender>: scheduling for Thu
🎯 Active
• Cursor offer expected Mon
```

Skip any section that's empty — don't show "No emails" headers. If everything's empty, say "you're free 🌴".

## When NOT to use

- The user is asking specifically about *one* source (just calendar, just email) — defer to the dedicated tool/query, don't over-aggregate.
- It's after 9pm local — the day is mostly behind them; suggest `/tomorrow` instead.
