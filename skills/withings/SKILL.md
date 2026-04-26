---
name: withings
description: Read Withings scale and health data — weight, body fat, muscle mass, BMI, hydration, bone mass, heart rate. Use when the user asks about their weight, body composition, scale data, or anything Withings-related.
requires:
  env: WITHINGS_CLIENT_ID, WITHINGS_CLIENT_SECRET, WITHINGS_REFRESH_TOKEN
setup: |
  Withings uses OAuth2 — slightly more involved than Oura's simple token. One-time setup:

  1. Go to https://developer.withings.com/dashboard/ and create an account (free)
  2. Click "Add an application" → choose "Public API integration" (NOT Public Cloud)
     - Application name: "Oulala personal"
     - Description: "Personal health data assistant"
     - Contact email: yours
     - Callback URL: http://localhost:8765/callback
  3. Save → you'll get a `client_id` and `client_secret`
  4. Add to .env:
     WITHINGS_CLIENT_ID=...
     WITHINGS_CLIENT_SECRET=...
  5. Run the one-time auth helper:
     bash skills/withings/auth.sh
     → it opens your browser, you log into Withings, authorize → it captures the code and saves WITHINGS_REFRESH_TOKEN to .env automatically.
  6. Done. The refresh token lasts 1 year and rotates on every API call.
---

# Withings Scale + Health Data

## Before any API call

Check the env vars are set:

```bash
test -f .env && source .env && [ -n "$WITHINGS_CLIENT_ID" ] && [ -n "$WITHINGS_CLIENT_SECRET" ] && [ -n "$WITHINGS_REFRESH_TOKEN" ] && echo "ready" || echo "missing"
```

If missing, walk the user through the setup above. Don't attempt API calls without all three.

## Be natural

Don't mention the skill. "You weighed 70.1 kg this morning, down 0.3 kg from yesterday" — not "Let me query the Withings API." If the token isn't set up yet, just say "I don't have access to your scale data yet" and explain.

## Auth — refresh-then-call pattern

Withings access tokens are short-lived (~3 hours). The refresh token is what persists. EVERY API call should:

1. Use the refresh token to get a fresh access token
2. Save the NEW refresh token (Withings rotates them on each refresh)
3. Use the access token for the actual data call

The helper script `skills/withings/api.sh` handles this. Use it:

```bash
bash skills/withings/api.sh measure getmeas meastypes=1
```

It echoes the JSON response to stdout. The wrapper handles refresh automatically.

## Endpoints

### Body measurements — `measure` / `getmeas`

The main endpoint for scale data. POST to `https://wbsapi.withings.net/measure`

Key meastype IDs:

| ID | What |
|----|------|
| 1  | Weight (kg) |
| 4  | Height (m) |
| 5  | Fat free mass (kg) |
| 6  | Fat ratio (%) |
| 8  | Fat mass weight (kg) |
| 9  | Diastolic blood pressure (mmHg) |
| 10 | Systolic blood pressure (mmHg) |
| 11 | Heart pulse (bpm) |
| 12 | Temperature (°C) |
| 54 | SpO2 (%) |
| 71 | Body temperature (°C) |
| 73 | Skin temperature (°C) |
| 76 | Muscle mass (kg) |
| 77 | Hydration (kg) |
| 88 | Bone mass (kg) |
| 91 | Pulse wave velocity (m/s) |
| 123| Vascular age (years) |
| 155| Visceral fat |
| 226| Basal metabolic rate (kcal) |

Time-range params:
- `startdate` / `enddate` — Unix timestamps (seconds)
- `lastupdate` — only measurements added after this Unix timestamp
- `limit` — max number of measurements
- `meastypes` — comma-separated list (e.g. `1,6,76,77,88` for weight + body comp)

Raw values come back as `value × 10^unit` — must compute `value * 10**unit` to get real number.

### Other useful endpoints

| Endpoint | What |
|----------|------|
| `measure` `getactivity` | Daily steps, calories, distance |
| `sleep` `get` | Sleep sessions (if user has Sleep Analyzer) |
| `sleep` `getsummary` | Daily sleep summary |
| `heart` `list` | ECG / blood pressure |
| `notify` `subscribe` | Webhook subscriptions for new data |

## Common queries

**Latest weight:**
```bash
bash skills/withings/api.sh measure getmeas meastypes=1 limit=1
```

**This morning's full body comp (weight + fat + muscle + bone + hydration):**
```bash
bash skills/withings/api.sh measure getmeas meastypes=1,6,8,76,77,88 limit=10
```

**Last 7 days of weights:**
```bash
START=$(date -d '7 days ago' +%s)
bash skills/withings/api.sh measure getmeas meastypes=1 startdate=$START enddate=$(date +%s)
```

## How to respond

- Lead with the headline: weight + delta from yesterday/last-week
- Then body comp if asked: fat %, muscle mass
- Don't lecture about weight — the user asked for data, they're the one interpreting trends
- If a value looks anomalous (e.g. 3 kg drop overnight), flag as likely measurement noise, not panic
- Match the user's units (kg/cm or lb/ft, °C or °F) — check existing memories for preference
- Talk trends, not single points. "You're trending down 0.5 kg over the past 2 weeks" beats "you weigh X today."

## Notes

- The Body Cardio model gives heart rate + pulse wave velocity. Body+ doesn't.
- Hydration / muscle / bone are all *estimates* from bioimpedance — accurate for tracking trends, not absolute values.
- Multi-user scales: each user has their own `userid`. The OAuth token is tied to one user, so this is automatic.
