# Phase 3: Verify

You are the Kova orchestrator executing Phase 3 for item **{{ITEM_NUMBER}}** of **{{TOTAL_ITEMS}}**.

## Instructions

Run the 7-layer verification gate. This is the same gate as `verify-on-stop.sh`
but failures are handled by the loop's fix-and-retry logic.

### Step 3.1: Detect Stack

```bash
source .claude/hooks/lib/detect-stack.sh
detect_pm
detect_languages
```

### Step 3.2: Run Each Layer

Run applicable layers sequentially. Record full output of any failures.

**Layer 1 — Build:** `$PM run build` / `go build ./...` / `cargo build` / etc.
**Layer 2 — Unit tests (retry once):** `$PM run test` / `pytest` / `go test ./...` / etc.
**Layer 3 — Integration tests (if configured):** `$PM run test:integration`
**Layer 4 — E2E (if Playwright installed):** `$PM run test:e2e` / `npx playwright test`
**Layer 5 — Lint:** `$PM run lint` / `ruff check .` / `golangci-lint run` / etc.
**Layer 6 — Type check:** `$PM run typecheck` / `mypy .` / `go vet ./...` / etc.
**Layer 7 — Security audit (warn only):** `$PM audit` / equivalent

### Step 3.3: Parse Failures

For each failing layer, extract structured diagnostics:
- **Test failures:** file, line, test name, expected vs received
- **Lint errors:** rule, file:line, message
- **Type errors:** error code, file:line, type mismatch detail
- **Build errors:** module not found, undefined reference, etc.

Write failures to `.kova-loop/current-failures.md` with file:line detail.

### Step 3.4: Report Result

**All blocking layers pass (1-6):**
```
Phase 3 PASS. All 6 blocking layers green. [Layer 7 warnings if any]
```
Set `verify_result = "pass"`

**Any blocking layer failed:**
```
Phase 3 FAIL. Failed layers: [list]. [N] errors with file:line diagnostics.
```
Set `verify_result = "fail"`

## Key Rules
- NEVER skip any applicable layer
- ALWAYS record full error output for failing layers
- Layer 7 (security) is warn-only — it never blocks
- Retry unit/integration/E2E once before marking as failed (flaky test handling)
