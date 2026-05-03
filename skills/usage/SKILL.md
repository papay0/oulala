---
name: usage
description: Show Claude subscription usage — current 5-hour session % and 7-day weekly % used, plus reset times. Mirrors the "Usage" view in the Claude.ai mobile app. Use when the user asks about their Claude usage, quota, limits, or how much of their session they've burned.
requires:
  bins: curl, python3
setup: |
  No setup. Reads the OAuth token Claude Code already stores at ~/.claude/.credentials.json.
---

# Claude Usage

Reports the same numbers Claude.ai shows in its Usage screen: current session and weekly limit, with utilization % and reset times.

## How it works

Anthropic returns rate-limit headers on every API response. Claude Code reads them; we just read them too. The relevant headers:

- `anthropic-ratelimit-unified-5h-utilization` — fraction of the 5-hour session used (0.0–1.0)
- `anthropic-ratelimit-unified-5h-reset` — Unix epoch seconds when the session resets
- `anthropic-ratelimit-unified-7d-utilization` — fraction of the 7-day weekly limit used
- `anthropic-ratelimit-unified-7d-reset` — Unix epoch seconds when the weekly resets

To trigger a response with those headers we make the cheapest possible call: `claude-haiku-4-5`, `max_tokens: 1`, prompt `"x"`. Cost is fractions of a cent and counts against the same limits we're measuring (so the report is honestly post-call).

## Run it

```bash
bash skills/usage/run.sh
```

Output is plain text with two bars (session, weekly), percentages, and `resets in Xh Ym`.

## Auth

Reads the OAuth access token from `~/.claude/.credentials.json` (the file Claude Code itself writes when you log in with your Claude subscription). API key auth would also work but the headers are tied to the auth used; we want the *subscription* limits, so we use the OAuth token.

## When to use

The user mentions:
- "how much usage have I used", "what's my session at", "weekly limit", "quota"
- references to the Claude.ai app's Usage screen
- a Telegram `/usage` slash command

## When NOT to use

- The user is asking about API spend in dollars — that's a different question; this skill reports subscription utilization, not billing.
- The user is on an API-key-only setup (no Claude subscription); the headers will reflect API-key tier limits which may differ from what they see in the Claude.ai app.
