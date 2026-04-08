# Oulala

[oulala.app](https://oulala.app)

Your personal AI assistant. One command to install.

Oulala turns [Claude Code](https://code.claude.com) into a personal AI that lives on your machine. It has a personality, remembers your life, and you can talk to it from your phone.

## Install

```bash
curl -sL oulala.app/install | bash
```

## Commands

```
oulala start       Start Oulala with remote control
oulala update      Pull latest updates and merge
oulala sync setup  Set up cross-device memory sync
oulala help        Show all commands
```

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

- **brain/SOUL.md** — your AI's personality
- **brain/** — where it remembers things about you
- **skills/** — teach it new abilities (each skill is a markdown file)
- **.env** — API keys for skills

## Customize

```
~/.oulala/brain/SOUL.md    Change personality
~/.oulala/skills/*/SKILL.md    Add a skill
~/.oulala/.env    Add API keys
```

## Built with Claude Code, for Claude Code

No wrapper. No custom runtime. Your Claude subscription, used directly.

## License

MIT
