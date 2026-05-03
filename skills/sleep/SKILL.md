---
name: sleep
description: Show a sleep report — last night, 7-day average, 30-day average, plus trend direction. Use when the user asks how they slept, wants a sleep summary, or hits /sleep.
requires:
  env: OURA_TOKEN
---

# Sleep Report

Composes Oura's `daily_sleep` endpoint into a single report with three windows:
- **Last night** — score + key contributors (deep, REM, restfulness, total sleep)
- **7-day average** — score + delta vs. previous week
- **30-day average** — score + delta vs. previous month

## Run it

```bash
bash skills/sleep/run.sh
```

Output is plain text, ready to format for Telegram or print.

## What "trend" means

Up arrow if 7-day avg is ≥3 points above 30-day avg. Down arrow if ≥3 below. Otherwise flat.

## Interpretation rule

If the most-recent night's score is <70, lead with that — it's the freshest signal. Otherwise lead with the 7-day average so the user sees direction first.

## Format guidance (when sending to Telegram)

- **Lead with a short headline** that combines the score and a human read ("68 last night — short night").
- **Prose paragraph** for the why (what hurt, what held). Drop numbers in the sentence rather than a separate stats table — `(86)` after "deep held" reads better than a code block.
- **Bullets** for the coaching ask at the end (3 max).
- **Avoid monospace code-block tables.** They visually disconnect from the prose and look like a debug dump on mobile.
- **Tone:** friend who happens to track stats. Warm, direct, willing to nudge. Specific commitments ("bed by 12:30 AM") not vague ones ("get good sleep").
- **Length:** ~5–8 lines. Cut anything that doesn't change behavior or interpretation.

## When NOT to run

- The user's `OURA_TOKEN` isn't in `.env` — say so and skip.
- The user is asking about *upcoming* sleep (e.g. "what time should I go to bed") — that's a different question; this skill reports historical data only.
