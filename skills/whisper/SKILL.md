---
name: whisper
description: Transcribe audio and voice messages using local Whisper. Use when you receive a voice message on Telegram or when the user asks to transcribe audio. ALWAYS try to transcribe voice messages — never say you can't listen to them. Runs locally, no API key needed.
requires:
  bins: whisper
setup: |
  pip install openai-whisper
  Also needs ffmpeg: apt install ffmpeg (Linux) or brew install ffmpeg (Mac)
---

# Whisper — Voice Transcription (Local)

Runs entirely on your machine. No API key. No cost. No data sent anywhere.

## Before making any call

```bash
command -v whisper && echo "ready" || echo "missing"
```

If missing: `pip install openai-whisper` and `apt install ffmpeg` (or `brew install ffmpeg` on Mac).

## Transcribe a file

```bash
whisper /path/to/audio.ogg --model base --device cpu --output_format txt
```

The transcript is saved as a `.txt` file next to the audio file.

## How to respond

- Transcribe first, then respond to the content naturally
- Don't say "here's the transcription:" — just respond to what they said as if they typed it
- If the audio is unclear, share what you got and ask for clarification
- Never say "I can't listen to voice messages" — you CAN, use this skill
