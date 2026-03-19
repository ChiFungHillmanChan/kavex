# Contributing to Kavex

Welcome! Kavex makes Claude Code work better for every language and ecosystem. Contributions are appreciated — whether it's adding a new language, improving hooks, or fixing bugs.

## Running Tests Locally

Kavex uses [Bats](https://github.com/bats-core/bats-core) for shell testing. **All tests must pass before submitting a PR.**

```bash
# Install test dependencies (one time)
npm install

# Run full suite
npm test

# Run individual suites
npm run test:unit          # Unit tests (detect-stack, parse-prd, parse-failures)
npm run test:integration   # Integration tests (install, activate, deactivate, status)
npm run test:regression    # Regression tests (hook-name consistency)

# Run shellcheck (requires shellcheck installed)
npm run lint
```

### Prerequisites

- **jq** — `brew install jq` (macOS) / `apt install jq` (Linux)
- **shellcheck** — `brew install shellcheck` (macOS) / `apt install shellcheck` (Linux)
- **Node.js** — For bats test runner (`npm install`)

## Adding Support for a New Language

1. **Detection** — Add lockfile/config detection in `hooks/lib/detect-stack.sh` (e.g., check for `go.mod`, `Cargo.toml`)
2. **Verification** — Add build, test, lint, and typecheck commands in `hooks/lib/verify-gate.sh`
3. **Formatting** — Add the formatter invocation in `hooks/format.sh`
4. **Verify command** — Update `commands/verify-app.md` to include the new language's tools
5. **Settings** — Update `.claude/settings.json` deny patterns if the language has generated files that should be protected
6. **Tests** — Add detection test cases in `tests/unit/detect-stack.bats`

## Adding a New Hook

Hooks are shell scripts in `hooks/` that run automatically based on tool matchers.

1. Create a new `.sh` file in `hooks/`
2. Register it in `hooks/hooks.json` (plugin mode) or `.claude/settings.json` (legacy mode) under the `hooks` key with a `matcher` (tool trigger) and `command` (path to script)
3. Add the hook to the install payload in `install.sh`
4. Update `kavex` CLI (`cmd_help`, `cmd_status`, `cmd_activate`) to reference the new hook
5. Run `npm run test:regression` to verify hook-name consistency
6. Hooks receive context via environment variables and stdin — see existing hooks for examples
7. Keep hooks fast; they run on every matched action

## Adding a New Command

Slash commands are Markdown files in `commands/`.

1. Create a `.md` file in `commands/` — the filename becomes the command name (e.g., `my-command.md` -> `/my-command`)
2. Write the prompt/instructions Claude should follow when the command is invoked
3. Use clear, imperative instructions
4. Reference existing commands for style and structure

## Updating Documentation

- English docs: `docs/en/README.md`
- Cantonese docs: `docs/zh-hk/README.md`
- Simplified Chinese docs: `docs/zh-cn/README.md`
- Keep all three in sync when making changes

## PR Expectations

- [ ] `npm run lint` — all shell scripts pass `shellcheck` with no warnings
- [ ] `npm test` — all tests pass (unit, integration, regression)
- [ ] Regression suite confirms hook-name consistency
- [ ] Tested with at least one language/ecosystem
- [ ] `README.md` updated if adding new language support or hooks
- [ ] Docs updated in all three languages if changing user-facing behavior
- [ ] No secrets, credentials, or API keys committed
- [ ] Keep changes focused — one feature or fix per PR
