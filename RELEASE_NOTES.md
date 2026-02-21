# Release Notes

## v0.2.0 (2026-02-21)

Kova v0.2.0 focuses on reliability controls and operability for autonomous loops.

### Highlights

- Added rate-limiting primitives in `.claude/hooks/lib/rate-limiter.sh` to cap repeated loop invocations.
- Added circuit-breaker logic in `.claude/hooks/lib/circuit-breaker.sh` to stop stuck/no-progress loops with a clear report.
- Integrated both controls into `.claude/hooks/kova-loop.sh`.
- Added `kova-monitor` tmux dashboard with `start`, `attach`, `stop`, `status`, and `dashboard`.
- Extended installer with global mode (`install.sh --global`) and setup flow support.
- Updated install payload to include new loop libraries and monitor binary.

### Testing

- Full Bats suite passing: **177 / 177**.
- New tests shipped in this release:
  - `tests/unit/rate-limiter.bats`
  - `tests/unit/circuit-breaker.bats`
  - `tests/unit/kova-monitor.bats`
  - `tests/integration/monitor.bats`
  - `tests/integration/global-install.bats`

### Upgrade Notes

- Existing per-project installs continue to work.
- To use global CLI commands, run:

```bash
bash install.sh --global
kova setup
```

- `jq` remains a required runtime dependency for hooks.
