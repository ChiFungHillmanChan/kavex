# Release Notes

## v0.3.0 (2026-03-11)

Kavex v0.3.0 introduces plugin distribution, cross-model diagnostics, and repo restructuring for public release.

### Highlights

- **Plugin Distribution** — Install via `claude /install kavex` or `claude /install kavex-full` (no git clone needed).
- **Repo Restructure** — Hooks, commands, and scripts moved to top-level directories for cleaner layout.
- **Cross-Model Diagnostics** — Optional Codex CLI integration for cross-model failure diagnosis and code review.
- **Safer Loop Commits** — Replaced `git add -A` with filtered staging that excludes sensitive files and unrelated changes.
- **Legacy Install Fix** — Fresh installs now work immediately without needing `kavex activate` to repair hook paths.
- **CI Updated** — GitHub Actions workflow now validates the actual repo layout.

### Breaking Changes

- Source file paths changed: `hooks/` (was `.claude/hooks/`), `commands/` (was `.claude/commands/`), `scripts/` (was root-level).
- Existing legacy installs are unaffected (files are still installed into `.claude/` in target projects).

### Testing

- Full Bats suite passing: **all tests green** (count auto-updated by CI badge).
- New tests shipped: codex-assist, kavex-statusline, verify-on-stop self-heal, hook-name consistency regression.

### Upgrade Notes

- Plugin users: run `claude /install kavex-full` to get the latest.
- Legacy users: re-run `bash install.sh` in your project to pick up path fixes.
- `jq` remains a required runtime dependency for hooks.

---

## v0.2.0 (2026-02-21)

Kavex v0.2.0 focuses on reliability controls and operability for autonomous loops.

### Highlights

- Added rate-limiting primitives in `hooks/lib/rate-limiter.sh` to cap repeated loop invocations.
- Added circuit-breaker logic in `hooks/lib/circuit-breaker.sh` to stop stuck/no-progress loops with a clear report.
- Integrated both controls into `hooks/kavex-loop.sh`.
- Added `kavex-monitor` tmux dashboard with `start`, `attach`, `stop`, `status`, and `dashboard`.
- Extended installer with global mode (`install.sh --global`) and setup flow support.
- Updated install payload to include new loop libraries and monitor binary.

### Testing

- Full Bats suite passing: **177 / 177**.
- New tests shipped in this release:
  - `tests/unit/rate-limiter.bats`
  - `tests/unit/circuit-breaker.bats`
  - `tests/unit/kavex-monitor.bats`
  - `tests/integration/monitor.bats`
  - `tests/integration/global-install.bats`

### Upgrade Notes

- Existing per-project installs continue to work.
- To use global CLI commands, run:

```bash
bash install.sh --global
kavex setup
```

- `jq` remains a required runtime dependency for hooks.
