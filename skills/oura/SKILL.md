---
name: oura
description: Read Oura Ring health data — sleep, activity, readiness, heart rate, stress, workouts, and more. Use when the user asks about their sleep, health, fitness, recovery, HRV, steps, or anything related to their Oura Ring.
requires:
  env: OURA_TOKEN
setup: |
  1. Go to https://cloud.ouraring.com/personal-access-tokens
  2. Create a new token (select all scopes)
  3. Add to your .env file: OURA_TOKEN=your_token_here
---

# Oura Ring

## Before making any API call

FIRST check that `.env` exists and has `OURA_TOKEN` set:

```bash
test -f .env && grep -q 'OURA_TOKEN=.' .env && echo "ready" || echo "missing"
```

If missing, tell the user how to set it up (see setup above). Do NOT attempt API calls without a token.

## Be natural

Don't mention the skill by name. Just get the data and talk about it naturally. "You slept 7 hours, readiness is 82" not "Let me check the Oura skill." If the token isn't set up, just say "I don't have access to your Oura data yet" and explain setup.

## Authentication

```bash
source .env && curl -s -H "Authorization: Bearer $OURA_TOKEN" "<url>"
```

## Base URL

`https://api.ouraring.com/v2/usercollection`

## Endpoints

All accept `?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`. Default to today if no date specified.

| What | Endpoint |
|------|----------|
| Sleep score & summary | `/daily_sleep` |
| Detailed sleep sessions | `/sleep` |
| Readiness score | `/daily_readiness` |
| Activity & steps | `/daily_activity` |
| Heart rate (5min intervals) | `/heartrate` |
| Stress & recovery | `/daily_stress` |
| Blood oxygen (SpO2) | `/daily_spo2` |
| Workouts | `/workout` |
| Optimal bedtime | `/sleep_time` |
| VO2 max | `/vo2_max` |

## How to respond

- Lead with the headline number, then details if asked
- "You slept 7h 12m, sleep score 85. Deep sleep was solid at 1h 40m."
- Don't dump raw JSON — summarize like a friend reading your stats
- Compare to recent trends when possible ("better than your average this week")
- If readiness is low, proactively mention it
- One API call at a time. Don't fetch sleep + readiness + activity in parallel unless the user asked for a full overview.

## Examples

**"How did I sleep?"**
```bash
source .env && curl -s -H "Authorization: Bearer $OURA_TOKEN" \
  "https://api.ouraring.com/v2/usercollection/daily_sleep?start_date=$(date +%Y-%m-%d)"
```

**"What's my readiness?"**
```bash
source .env && curl -s -H "Authorization: Bearer $OURA_TOKEN" \
  "https://api.ouraring.com/v2/usercollection/daily_readiness?start_date=$(date +%Y-%m-%d)"
```

**"How was my week?"**
```bash
source .env && START=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d) && \
curl -s -H "Authorization: Bearer $OURA_TOKEN" \
  "https://api.ouraring.com/v2/usercollection/daily_sleep?start_date=$START&end_date=$(date +%Y-%m-%d)"
```
