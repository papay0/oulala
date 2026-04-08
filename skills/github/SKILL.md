---
name: github
description: GitHub operations — PRs, issues, CI status, code review. Use when the user asks about pull requests, issues, builds, or anything GitHub-related.
requires:
  bins: gh
setup: |
  1. Install gh: brew install gh (or apt install gh)
  2. Authenticate: gh auth login
---

# GitHub

Uses the `gh` CLI.

## Before making any call

```bash
command -v gh && gh auth status 2>/dev/null && echo "ready" || echo "missing"
```

## Don't narrate

Just check and report. "PR #55 is ready to merge, CI is green" not "I'm going to check the status of your pull request."

## Commands

### Pull Requests

```bash
# List open PRs
gh pr list --repo owner/repo

# PR details
gh pr view 55 --repo owner/repo

# CI status
gh pr checks 55 --repo owner/repo

# Create PR
gh pr create --title "feat: add feature" --body "Description"

# Merge
gh pr merge 55 --squash --repo owner/repo
```

### Issues

```bash
# List open issues
gh issue list --repo owner/repo --state open

# Create issue
gh issue create --title "Bug: something broken" --body "Details..."

# Close
gh issue close 42 --repo owner/repo
```

### CI / Workflow Runs

```bash
# Recent runs
gh run list --repo owner/repo --limit 5

# View run
gh run view <run-id> --repo owner/repo

# Failed logs only
gh run view <run-id> --repo owner/repo --log-failed

# Re-run failed
gh run rerun <run-id> --failed --repo owner/repo
```

### Quick queries

```bash
# Repo stats
gh api repos/owner/repo --jq '{stars: .stargazers_count, forks: .forks_count}'

# PR with JSON
gh pr list --json number,title,state --jq '.[] | "\(.number): \(.title)"'
```

## How to respond

- Lead with status: "3 open PRs, all CI green"
- For CI failures, show the relevant error, not the full log
- When creating PRs/issues, confirm the title before creating
