---
name: weather
description: Get current weather and forecasts for any location. Use when the user asks about weather, temperature, rain, or forecasts. No API key needed.
---

# Weather

No setup needed. Uses wttr.in.

## Don't narrate

Just check the weather and tell them naturally. "It's 65°F and cloudy in SF, might rain later."

## Commands

```bash
# Current weather one-liner
curl -s "wttr.in/San+Francisco?format=3"

# Detailed with feels-like, wind, humidity
curl -s "wttr.in/San+Francisco?format=%l:+%c+%t+(feels+like+%f),+%w+wind,+%h+humidity"

# Will it rain?
curl -s "wttr.in/San+Francisco?format=%c+%p"

# 3-day forecast
curl -s "wttr.in/San+Francisco"

# JSON output for parsing
curl -s "wttr.in/San+Francisco?format=j1"
```

Replace `San+Francisco` with the user's city. Use `+` for spaces.

## How to respond

- Lead with what matters: temperature and conditions
- Mention rain only if it's likely
- If they're planning something, factor in the forecast
- Keep it casual: "grab a jacket" not "precipitation expected"
