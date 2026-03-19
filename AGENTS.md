# Repository Guidelines

## Project Structure & Module Organization
Kavex is a Bash-first repository centered on portable Claude Code automation.

- Root CLI/install scripts: `kavex`, `kavex-monitor`, `install.sh`
- Core protocol assets: `.claude/settings.json`, `.claude/hooks/*.sh`, `.claude/hooks/lib/*.sh`
- Slash-command prompts: `.claude/commands/**/*.md` (including `kavex/phases/`)
- Tests: `tests/unit`, `tests/integration`, `tests/regression`, shared helpers in `tests/helpers`
- Documentation: `README.md`, `CONTRIBUTING.md`, and localized docs in `docs/en`, `docs/zh-hk`, `docs/zh-cn`

## Build, Test, and Development Commands
- `npm install`: install Bats and assertion helpers.
- `npm test`: run all test suites (`unit`, `integration`, `regression`).
- `npm run test:unit`: run fast logic tests for parser/detector/libs.
- `npm run test:integration`: verify install/activate/status workflows.
- `npm run test:regression`: check cross-file consistency (for example hook names).
- `npm run lint`: run `shellcheck -x -S warning` across scripts and hook libs.
- `bash install.sh --dry-run`: preview install payload changes safely.

## Coding Style & Naming Conventions
- Use Bash for runtime scripts (`#!/bin/bash`) and Bats for tests (`#!/usr/bin/env bats`).
- Follow existing style: 2-space indentation, explicit helper functions, and readable guard clauses.
- Use `snake_case` for function names (`detect_languages`) and `cmd_<name>` for CLI handlers (`cmd_status`).
- Use kebab-case filenames for scripts/tests (`verify-on-stop.sh`, `hook-name-consistency.bats`).
- Keep reusable logic in `.claude/hooks/lib/`; keep hook entrypoints thin.

## Testing Guidelines
- Testing stack: `bats`, `bats-support`, `bats-assert`.
- Add or update tests in the matching suite by behavior scope (unit vs integration vs regression).
- Use descriptive test names in `@test "component: behavior"` format.
- Run `npm run lint` and `npm test` before opening a PR; CI enforces both on Linux and macOS.

## Commit & Pull Request Guidelines
- Current Git history is minimal (`Initial commit`), so no strict historical convention exists yet.
- Use short imperative subjects; prefer Conventional Commit prefixes (`feat:`, `fix:`, `chore:`) for new consistency.
- Keep PRs focused to one feature/fix, include rationale, and link related issues.
- Match `CONTRIBUTING.md` checklist: passing lint/tests, docs updates for user-facing changes (all 3 locales), and no committed secrets.

## Security & Configuration Tips
- Never commit credentials (`.env`, keys, tokens, `secrets/` content).
- `jq` is required by hooks; validate availability in local/dev environments.
- When adding hooks/commands, update both `.claude/settings.json` and `install.sh` payload logic together.
