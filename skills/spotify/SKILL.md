---
name: spotify
description: Control Spotify playback — play, pause, skip, search, queue. Use when the user asks to play music, check what's playing, or control playback. Requires Spotify Premium.
requires:
  bins: spogo
setup: |
  1. Install spogo: brew install steipete/tap/spogo
  2. Import your Spotify cookies: spogo auth import --browser chrome
  3. Test: spogo status
---

# Spotify

Uses the `spogo` CLI for Spotify control.

## Before making any call

```bash
command -v spogo && echo "ready" || echo "missing"
```

If missing, tell the user: "You need spogo to control Spotify. Run: `brew install steipete/tap/spogo` then `spogo auth import --browser chrome`"

## Don't narrate

Just do it. "Playing Daft Punk" not "I'm going to use the Spotify skill to search for and play Daft Punk."

## Commands

```bash
# Search and play
spogo search track "Daft Punk Get Lucky"
spogo play

# Playback controls
spogo pause
spogo next
spogo prev

# What's playing
spogo status

# Devices
spogo device list
spogo device set "Living Room Speaker"

# Search types
spogo search track "query"
spogo search album "query"
spogo search artist "query"
spogo search playlist "query"
```

## How to respond

- When playing: "Playing Get Lucky by Daft Punk"
- When asked what's playing: "You're listening to [song] by [artist]"
- Keep it casual, like a friend with the aux cord
