---
name: bluebubbles
description: Read and send iMessages via the user's BlueBubbles Server running on their Mac. Use when the user asks about iMessages — reading a conversation, searching for a person, sending a message, reacting, etc. The Mac must be awake and BlueBubbles Server running.
requires:
  env: [BLUEBUBBLES_URL, BLUEBUBBLES_PASSWORD]
setup: |
  1. Install BlueBubbles Server on the user's Mac (brew install --cask bluebubbles) and complete the setup wizard.
  2. In BlueBubbles Settings → copy the Server Password.
  3. In BlueBubbles Home → copy the Server URL (if using Cloudflare quick tunnel, this URL changes on each restart).
  4. Add to ~/.oulala/.env:
     BLUEBUBBLES_URL=https://<server>.trycloudflare.com
     BLUEBUBBLES_PASSWORD=<password>
  5. The Mac must stay awake for BlueBubbles to be reachable. If the Mac sleeps, the Cloudflare tunnel closes and all calls will fail. Use `caffeinate -dims` to prevent sleep when needed.
---

# BlueBubbles — iMessage via REST

BlueBubbles runs on the user's Mac, bridges iMessage, and exposes a REST API reachable through a Cloudflare tunnel (or direct LAN address). Oulala reads that API to search messages, read conversations, and send replies — without needing a local Mac.

## Be natural

Don't mention the skill by name. Just do the task. "You have 3 unread from X" — not "Let me query BlueBubbles...". Summarize messages like a person reading them, not a JSON blob.

## Before any API call

Check credentials exist:

```bash
test -f ~/.oulala/.env && grep -q 'BLUEBUBBLES_PASSWORD=.' ~/.oulala/.env \
  && echo "ready" || echo "missing — user needs to set BLUEBUBBLES_URL and BLUEBUBBLES_PASSWORD in .env"
```

## Auth model

Every request takes `?password=$BLUEBUBBLES_PASSWORD` as a query param. Always source the env first:

```bash
source ~/.oulala/.env
```

## Handling a stale tunnel URL

BlueBubbles quick tunnels regenerate on restart. If a call returns **Cloudflare Error 1033** / DNS failure / HTTP 404 at the API root, the tunnel is down or the URL changed. Tell the user: "The BlueBubbles tunnel is unreachable — either the Mac is asleep or the URL changed. Wake the Mac (or update `BLUEBUBBLES_URL` in `.env`) and try again."

## Ping (sanity check)

```bash
source ~/.oulala/.env && \
  curl -s "$BLUEBUBBLES_URL/api/v1/ping?password=$BLUEBUBBLES_PASSWORD"
```

Expected: `{"status":200,"message":"Ping received!","data":"pong"}`.

## List all contacts (for name lookups)

```bash
source ~/.oulala/.env && \
  curl -s "$BLUEBUBBLES_URL/api/v1/contact?password=$BLUEBUBBLES_PASSWORD"
```

Returns an array of contacts with `phoneNumbers`, `emails`, `firstName`, `lastName`, `displayName`. Use this to resolve phone numbers in message `handle.address` to real names.

## List chats

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/chat/query?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"limit":50,"offset":0,"with":["participants","lastMessage"],"sort":"lastmessage"}'
```

Each chat has `guid`, `displayName`, `participants`, `lastMessage`.

Note: BlueBubbles does not reliably report unread counts (the Messages app often auto-marks read). To find "what just came in," query recent messages instead and filter `isFromMe: false` + `dateCreated > cutoff`.

## Get recent messages in a chat

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/message/query?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"chatGuid":"<chat-guid>","limit":50,"offset":0,"sort":"DESC","with":["chats","attachments","handle"]}'
```

Each message has `guid`, `text`, `dateCreated` (unix ms), `isFromMe`, `handle.address`.

## Get recent inbound messages (pseudo-unread)

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/message/query?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"limit":50,"offset":0,"sort":"DESC","with":["chats","handle","chat.participants"]}'
```

Filter client-side: `isFromMe === false` and `dateCreated` within the window the user cares about. Group by chat for readability.

## Send a text

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/message/text?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
      "chatGuid":"<chat-guid>",
      "tempGuid":"ou-'$(date +%s%N)'",
      "message":"hello",
      "method":"private-api"
    }'
```

`method:"private-api"` enables richer features if the Private API is configured on the Mac. Falls back to AppleScript automatically otherwise.

## Send a tapback reaction (requires Private API on Mac)

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/message/react?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
      "chatGuid":"<chat-guid>",
      "selectedMessageGuid":"<message-guid>",
      "reaction":"love"
    }'
```

Valid reactions: `love`, `like`, `dislike`, `laugh`, `emphasize`, `question`. Prefix with `-` to remove.

## Reply in a thread

Add `selectedMessageGuid` and `partIndex` to a regular text send.

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/message/text?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
      "chatGuid":"<chat-guid>",
      "tempGuid":"ou-'$(date +%s%N)'",
      "message":"replying in thread",
      "selectedMessageGuid":"<message-guid>",
      "partIndex":0,
      "method":"private-api"
    }'
```

## Send with iMessage effect (requires Private API on Mac)

```bash
source ~/.oulala/.env && \
  curl -s -X POST "$BLUEBUBBLES_URL/api/v1/message/text?password=$BLUEBUBBLES_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{
      "chatGuid":"<chat-guid>",
      "tempGuid":"ou-'$(date +%s%N)'",
      "message":"surprise",
      "effectId":"com.apple.messages.effect.CKConfettiEffect",
      "method":"private-api"
    }'
```

Effects: `CKConfettiEffect`, `CKFireworksEffect`, `CKLasersEffect`, `CKBalloonsEffect`, `CKHappyBirthdayEffect`, `CKHeartEffect`, `CKShootingStarEffect`, `CKSparkleEffect`, `CKEchoEffect`, `CKInvisibleInkEffect`, `CKGentleEffect`, `CKLoudEffect`, `CKSlamEffect`.

## SIP / Private API note

Full Private API features (reactions, edits, effects) require SIP (System Integrity Protection) to be disabled on the user's Mac. Basic send/receive works without it. Don't push the user toward disabling SIP unless they ask — basic texting covers most needs and keeps their Mac secure.

## Security

- The Cloudflare tunnel URL + password together grant full iMessage access. Both are secrets.
- Keep `BLUEBUBBLES_PASSWORD` in `.env`, which should be gitignored.
- Messages flow Mac → Cloudflare → VPS over HTTPS. Cloudflare sees metadata only; content is encrypted in transit.
