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

Oulala is not a new AI runtime. It's a configuration layer on top of Claude Code:

- **SOUL.md** defines your AI's personality — rename it, make it funny, make it serious, make it yours
- **skills/** teach it new abilities — each skill is just a markdown file
- **memory/** is where it remembers things about you — plain markdown you can read and edit
- **.env** stores API keys for skills (Oura, etc.)

When you talk to Oulala, you're talking to Claude Code with a soul.

## Customize

**Change the personality** — edit `~/.oulala/SOUL.md`

**Add a skill** — create `~/.oulala/skills/your-skill/SKILL.md` with instructions for how to use an API

**Add an API key** — edit `~/.oulala/.env`

**Update** — tell your AI "update yourself" or run `./bin/update.sh`

## Built with Claude Code, for Claude Code

Oulala is 100% built on the Anthropic stack. No wrapper, no custom runtime, no third-party agent. Your Claude subscription, used directly.

## License

MIT
