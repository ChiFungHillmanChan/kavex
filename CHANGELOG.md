# Changelog

## [0.3.0] - 2026-03-11

### Added

- **Plugin Distribution** — Kavex is now available as a Claude Code plugin
  - `kavex` (lightweight): slash commands + engineering protocol skill
  - `kavex-full` (complete): + hooks, verification gate, auto-format, commit gate, team loop
  - Plugin manifests in `.claude-plugin/` and `plugins/kavex/.claude-plugin/`
  - `hooks/hooks.json` for plugin hook definitions using `CLAUDE_PLUGIN_ROOT`

- **Cross-Model Diagnostics** — Optional Codex CLI integration
  - `hooks/lib/codex-assist.sh` — Send failure context to Codex for cross-model diagnosis
  - `hooks/lib/run-code-review.sh` — Optional Codex review alongside Claude reviewers
  - Portable timeout handling (no GNU coreutils dependency)
  - Non-blocking: loop continues if Codex unavailable

- **Engineering Protocol Skill** — `CLAUDE.md` repackaged as a discoverable skill
  - `skills/engineering-protocol/SKILL.md`

- **Kavex Planning Command** — `/kavex:plan` interactive planning with clarifying questions

### Changed

- **Repo Restructure** — Hooks, commands, and scripts moved to top-level directories
  - `hooks/` (was `.claude/hooks/`)
  - `commands/` (was `.claude/commands/`)
  - `scripts/` (was root-level `kavex`, `kavex-monitor`)
  - Legacy install continues to copy into `.claude/` for target projects
- **Atomic Per-Item Commits** — Replaced `git add -A` with snapshot-based staging
  - Snapshots working tree state before each Claude session
  - Only stages files that actually changed during the iteration (diff against snapshot)
  - New untracked files only staged if they appeared during the iteration (not pre-existing)
  - Sensitive file patterns (`*.env`, `*.pem`, `*.key`, `*.p12`, `credentials/`, `secrets/`) always excluded
- **Legacy Install Fix** — `install.sh` now generates correct `.claude/hooks/` paths in settings
  - Previously copied repo's `settings.json` which referenced `$CLAUDE_PROJECT_DIR/hooks/`
  - Fresh legacy installs now work without needing `kavex activate` to repair paths
- **CI Updated** — GitHub Actions workflow references current repo layout (`scripts/`, `hooks/`)

### Fixed

- Legacy install path mismatch: `settings.json` hook paths now match installed file locations
- CI workflow linting non-existent `.claude/hooks/` paths
- `CONTRIBUTING.md` referenced old `.claude/hooks/` source paths instead of `hooks/`
- Stale test counts in docs (177 → 213)

### Tests

- 36 new tests (213 total, up from 177)
  - Codex assist tests
  - Kavex statusline tests
  - Verify-on-stop self-heal tests
  - Hook-name consistency regression tests

## [0.2.0] - 2026-02-21

### Added

- **Rate Limiting** — Prevents API cost overruns during long loop sessions
  - Configurable via `MAX_INVOCATIONS_PER_HOUR` env var (default: 100)
  - Auto-detects API rate limit errors in Claude output (429, "too many requests")
  - Countdown display on stderr during wait periods
  - State tracked in `.kavex-loop/.rate_limit_state`

- **Circuit Breaker** — Stops loops that are clearly stuck
  - Trips after 3 consecutive stuck items (`CIRCUIT_BREAKER_THRESHOLD`)
  - Trips after 5 iterations with no file changes (`CIRCUIT_BREAKER_NO_PROGRESS`)
  - Writes detailed `CIRCUIT_BREAKER.md` report with next steps
  - Exit code 2 distinguishes circuit breaker from normal stuck (exit 1)

- **tmux Dashboard** (`kavex-monitor`) — Real-time loop monitoring
  - `kavex-monitor start <prd>` — split-pane tmux session (loop left, dashboard right)
  - `kavex-monitor attach/stop/status` — session management
  - Dashboard refreshes every 2s showing: progress, rate limit, circuit breaker, recent activity, verify results
  - Graceful fallback when tmux not installed

- **Global Install** — System-wide CLI availability
  - `install.sh --global` copies `kavex` + `kavex-monitor` to `~/.local/bin` (fallback `/usr/local/bin`)
  - PATH detection with actionable warnings
  - `--global --dry-run` preview mode
  - Per-project hooks still require `kavex install`

- **Setup Wizard** (`kavex setup`) — One-command project onboarding
  - Detects project stack
  - Runs install + activate
  - Shows final status summary

- `kavex monitor` command delegates to `kavex-monitor`

### Changed

- `kavex-loop.sh` now sources `rate-limiter.sh` and `circuit-breaker.sh`
- `kavex help` lists `setup` and `monitor` commands
- `install.sh` copies new lib files (`rate-limiter.sh`, `circuit-breaker.sh`) and `kavex-monitor`
- Loop summary now shows API call count

### Tests

- 65 new tests (177 total, up from 112)
  - `tests/unit/rate-limiter.bats` — 19 tests
  - `tests/unit/circuit-breaker.bats` — 18 tests
  - `tests/unit/kavex-monitor.bats` — 10 tests
  - `tests/integration/monitor.bats` — 10 tests
  - `tests/integration/global-install.bats` — 8 tests

## [0.1.0] - 2025-06-01

### Added

- Initial release
- 5 hooks: format, block-dangerous, protect-files, verify-on-stop, kavex-loop
- 7-layer verification gate
- 6-phase Team Loop with PRD parsing
- Stack detection for 7 ecosystems
- CLI with help, status, activate, deactivate, install
- 112 tests
