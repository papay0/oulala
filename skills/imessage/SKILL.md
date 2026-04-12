---
name: imessage
description: Read and send iMessages and SMS via macOS Messages.app. Use when the user asks about their texts, wants to read messages, send a text, check who messaged them, or reply to someone. macOS only.
requires:
  bins: imsg
  platform: darwin
setup: |
  1. Install imsg: brew install steipete/tap/imsg
  2. Grant Full Disk Access to your terminal (System Settings → Privacy & Security → Full Disk Access)
  3. First send will prompt for Automation permission for Messages.app — click OK
---

# iMessage

Uses the `imsg` CLI to read and send iMessages/SMS.

## Before making any call

Check platform and that `imsg` is installed:

```bash
[[ "$(uname)" == "Darwin" ]] && command -v imsg && echo "ready" || echo "missing"
```

If not macOS, tell the user: "iMessage only works on Mac — want me to send an email instead?"
If macOS but `imsg` missing, tell them to run `brew install steipete/tap/imsg`.

## Be natural

Don't mention the skill by name. Just read/send messages naturally.

## Common commands

### List recent chats
```bash
imsg chats --limit 10 --json
```

### Read message history
```bash
imsg history --chat-id <ID> --limit 20 --json
```

### Send a message
```bash
imsg send --to "+14155551212" --text "Hello!"
```

### Send with attachment
```bash
imsg send --to "+14155551212" --text "Check this out" --file /path/to/image.jpg
```

## How to respond

- When reading messages, summarize naturally: "Sarah texted you 20 min ago asking about dinner tonight"
- Don't dump raw JSON
- When sending, always confirm the recipient and message before sending — this is irreversible
- If the user says "text mom", find mom's chat first, confirm the number, then send

## Safety

- Always confirm before sending — a friend would double-check "send this to Mom?"
- Never send to unknown numbers without asking
- Never bulk-send messages
