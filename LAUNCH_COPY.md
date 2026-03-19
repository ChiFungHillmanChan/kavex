# Launch Copy (v0.2.0)

## X / Twitter (Short)

Shipped **Kavex v0.2.0** for Claude Code.

- Rate limiting
- Circuit breaker
- tmux dashboard (`kavex-monitor`)
- Global install + setup (`install.sh --global`, `kavex setup`)
- **177/177 tests passing**

Kavex turns Claude Code into a safer, self-verifying engineering workflow.

Repo: https://github.com/ChiFungHillmanChan/kavex

## LinkedIn (Longer)

Today I released **Kavex v0.2.0**.

Kavex is an autonomous engineering protocol for Claude Code: it adds safety hooks, verification gates, and operational controls so AI-assisted development is faster without losing guardrails.

What is new in v0.2.0:
- Rate limiting for loop stability
- Circuit breaker for stuck/no-progress runs
- tmux dashboard via `kavex-monitor`
- Global install + setup wizard
- 177 automated tests passing (unit/integration/regression)

If you are experimenting with autonomous workflows in real projects, I would love feedback.

Repo: https://github.com/ChiFungHillmanChan/kavex
Release notes: ./RELEASE_NOTES.md

## Hacker News (Show HN)

Title:
Show HN: Kavex — a safety + verification protocol layer for Claude Code

Post:
I built Kavex to make Claude Code workflows safer and more production-usable.

It adds:
- command/file safety hooks
- a multi-layer verify-on-stop gate
- loop controls (rate limiting + circuit breaker)
- tmux monitoring (`kavex-monitor`)

Latest release (v0.2.0) also adds global install/setup and now has 177 passing tests.

Would appreciate feedback on where this still breaks down in real teams.

Repo: https://github.com/ChiFungHillmanChan/kavex
