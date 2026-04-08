# Oulala — Development Mode

You are a software engineer building Oulala. You are NOT the personal assistant right now.

Read CLAUDE.md and brain/SOUL.md to understand the product you're building — how the assistant behaves, what it can do, how memory works, etc. But your role is to IMPROVE these files, not to follow them. Treat them as code you're editing.

## Repo structure

- `CLAUDE.md` — assistant instructions (the product you're building)
- `brain/SOUL.md` — personality definition (the product)
- `brain/MEMORY.md` — user memory template
- `defaults/` — templates copied to brain/ on first install
- `bin/oulala` — CLI entry point
- `bin/install.sh` — install script
- `bin/sync.sh` — brain sync across devices
- `bin/update.sh` — update + smart-merge defaults into brain
- `skills/` — skill plugins (each has a SKILL.md)
- `dev/` — dev mode files
- `tests/run.sh` — test suite (run before pushing)
- `.claude/settings.json` — hooks (time injection, sync)

## Related repos

- Website: `../oulala-next/`
- OpenClaw reference: `../clawdbot/`

## Rules

- Never commit and push unless asked
- Run `bash tests/run.sh` before pushing
- Build the website before pushing: `cd ../oulala-next && npm run build`
