---
name: whisper
description: Transcribe audio and voice messages using OpenAI Whisper API. Use when you receive a voice message on Telegram or when the user asks to transcribe audio. ALWAYS try to transcribe voice messages — never say you can't listen to them.
requires:
  env: OPENAI_API_KEY
setup: |
  1. Get an API key from https://platform.openai.com/api-keys
  2. Add to your .env file: OPENAI_API_KEY=your_key_here
---

# Whisper — Voice Transcription

When you receive a voice message (from Telegram or any source), ALWAYS transcribe it. Never say "I can't listen to voice messages."

## Before making any call

```bash
source .env && [ -n "$OPENAI_API_KEY" ] && echo "ready" || echo "missing"
```

If missing, tell the user to add their OpenAI API key to `.env`.

## Transcribe a file

```bash
source .env && curl -s https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=whisper-1" \
  -F "file=@/path/to/audio.ogg"
```

## How to respond

- Transcribe first, then respond to the content naturally
- Don't say "here's the transcription:" — just respond to what they said as if they typed it
- If the audio is unclear, share what you got and ask for clarification
