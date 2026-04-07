# Oulala

[oulala-ai.vercel.app](https://oulala-ai.vercel.app)

Your personal AI assistant. One command to install.

Oulala turns [Claude Code](https://code.claude.com) into a personal AI that lives on your machine. It has a personality, remembers your life, and you can talk to it from your phone.

## Install

```bash
curl -sL oulala-ai.vercel.app/install | bash
```

This installs Claude Code (if needed), sets up Oulala, and starts a session with remote control — open the Claude Code app on your phone and connect.

## What it can do

- Manage your calendar
- Read and reply to emails
- Send and read iMessages (macOS)
- Check your health data (Oura Ring, etc.)
- Browse the web
- Make reservations
- Write and ship code
- Set reminders and recurring routines
- Remember people, preferences, and details across conversations

All on your machine. Your data stays local.

## How it works

Oulala is a configuration layer on top of Claude Code:

- **brain/SOUL.md** defines your AI's personality — rename it, make it funny, make it serious, make it yours
- **brain/** is where it remembers things about you — plain markdown you can read and edit
- **skills/** teach it new abilities — each skill is just a markdown file
- **.env** stores API keys for skills (Oura, etc.)

## Customize

**Change the personality** — edit `~/.oulala/brain/SOUL.md`

**Add a skill** — create `~/.oulala/skills/your-skill/SKILL.md`

**Add an API key** — edit `~/.oulala/.env`

**Update** — tell your AI "update yourself"

## Sync across devices

Run Oulala on your Mac and your VPS with the same memories:

```bash
# On your main device:
"set up sync"

# On a new device after installing:
"connect my brain"
```

Your memories sync automatically to a private GitHub repo. API keys stay per-device.

## Built with Claude Code, for Claude Code

Oulala is 100% built on the Anthropic stack. No wrapper, no custom runtime, no third-party agent. Your Claude subscription, used directly.

## License

MIT
