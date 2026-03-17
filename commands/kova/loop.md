# /kova:loop
# Kova In-Session Loop — implement PRD items with engineering-team quality.
# Each item: snapshot → implement → verify → self-review → commit.
# Hooks enforce verification — Claude cannot skip or bypass them.
#
# Usage: /kova:loop <prd-file> [--dry-run] [--no-commit] [--max-fix-attempts N] [--mode=background]
#
# Default behavior changed in v0.4. Use `--mode=background` for the previous fire-and-forget mode.

You are the Kova Loop **orchestrator**. You implement PRD items in-session, fully visible to the user.

<CRITICAL>
Hooks are your safety net — they enforce what you cannot skip:
- `kova-commit-gate.sh` blocks commits without passing verification
- `verify-on-stop.sh` blocks early exit without passing lint/typecheck
- `block-dangerous.sh` blocks destructive commands

You call bash helper functions for snapshot, verify, and commit.
You do the implementation, review, and decision-making yourself.
</CRITICAL>

---

## Step 1: Validate

The user argument is: `$ARGUMENTS`

If `$ARGUMENTS` is empty or blank, say:
```
Usage: /kova:loop <prd-file>
Example: /kova:loop docs/prd-auth.md
No PRD file specified. Run /kova:init to scaffold a new PRD file.
```
Then STOP.

Parse the PRD file path from `$ARGUMENTS` (first non-flag argument).
Parse flags: `--dry-run`, `--no-commit`, `--max-fix-attempts N`, `--mode=background`

Run these checks via Bash:
```bash
test -f "<prd-file>" && echo "PRD_OK" || echo "PRD_MISSING"
KOVA_LOOP="${CLAUDE_PLUGIN_ROOT:-}/hooks/kova-loop.sh"
[ -f "$KOVA_LOOP" ] || KOVA_LOOP=".claude/hooks/kova-loop.sh"
test -f "$KOVA_LOOP" && echo "LOOP_OK" || echo "LOOP_MISSING"
KOVA_LIB="$(dirname "$KOVA_LOOP")/lib"
test -f "$KOVA_LIB/detect-stack.sh" && echo "LIB_OK" || echo "LIB_MISSING"
test -f "$KOVA_LIB/kova-snapshot.sh" && echo "SNAPSHOT_OK" || echo "SNAPSHOT_MISSING"
test -f "$KOVA_LIB/kova-verify.sh" && echo "VERIFY_OK" || echo "VERIFY_MISSING"
test -f "$KOVA_LIB/kova-safe-commit.sh" && echo "COMMIT_OK" || echo "COMMIT_MISSING"
test -f "$KOVA_LIB/kova-cleanup.sh" && echo "CLEANUP_OK" || echo "CLEANUP_MISSING"
command -v jq &>/dev/null && echo "JQ_OK" || echo "JQ_MISSING"
git rev-parse --is-inside-work-tree 2>/dev/null && echo "GIT_OK" || echo "GIT_MISSING"
```

If any MISSING, report and STOP.

## Step 2: Mode routing

If `--mode=background` is in the arguments:
- Launch the bash orchestrator (legacy mode):
```bash
bash "$KOVA_LOOP" $ARGUMENTS 2>&1
```
- Use Bash tool with 600000ms timeout. Then report results from `.kova-loop/` and STOP.

Otherwise, continue with in-session orchestration (default).

## Step 3: Preview (dry-run)

Run a dry-run preview by sourcing the PRD parser:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
source "$KOVA_LIB/parse-prd.sh"
parse_prd "<prd-file>"
echo "Items: $PRD_ITEM_COUNT"
for i in "${!PRD_ITEMS[@]}"; do echo "  $((i+1)). ${PRD_ITEMS[$i]}"; done
echo "Already completed: $PRD_COMPLETED_COUNT"
```

If `--dry-run` was in `$ARGUMENTS`, STOP here.

Otherwise display the items and ask: **"Ready to start the Kova Loop. Type `go` to begin."**
Wait for confirmation.

## Step 4: In-session orchestration

### Setup
Determine the library path:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
```

### For each unchecked PRD item, follow this protocol:

**SNAPSHOT** — Before touching any code:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
source "$KOVA_LIB/detect-stack.sh"
source "$KOVA_LIB/kova-snapshot.sh"
kova_snapshot ".kova-loop"
echo "Snapshot taken at $(date)"
```

**IMPLEMENT** — Read relevant code, implement the item, write tests.
Use Read, Edit, Write, Glob, Grep, and Bash tools as needed.
Follow the engineering protocol in CLAUDE.md.

**VERIFY** — After implementation:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
source "$KOVA_LIB/detect-stack.sh"
source "$KOVA_LIB/parse-failures.sh"
source "$KOVA_LIB/verify-gate.sh"
source "$KOVA_LIB/kova-verify.sh"
kova_verify ".kova-loop"
echo "Exit: $?"
```

If FAIL:
- Read `.kova-loop/parsed-failures-latest.md` to understand what failed
- Fix the issues
- Re-run VERIFY
- Max 5 attempts per item (or `--max-fix-attempts N`). If stuck after max attempts, log it and move to next item.

**REVIEW** — Self-review the diff before committing:
```bash
git diff HEAD
```
Check against this checklist:
- Security: injection, XSS, secrets in code, unsafe eval
- Logic: off-by-one, null handling, race conditions
- Tests: happy path + edge cases + expected errors covered
- No debug output left in (console.log, print, etc.)

If HIGH severity issues found: fix them and re-run VERIFY.

**COMMIT** — Stage and commit only Claude's changes:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
source "$KOVA_LIB/detect-stack.sh"
source "$KOVA_LIB/kova-safe-commit.sh"
kova_safe_commit <ITEM_NUM> "<SHORT_DESCRIPTION>" "<NO_COMMIT_FLAG>" ".kova-loop"
echo "Exit: $?"
```

If `kova_safe_commit` refuses (missing snapshot), re-run SNAPSHOT then retry COMMIT.

### Progress display

After each item, display progress:
```
[1/5] ✓ Add user auth endpoint (commit abc1234)
[2/5] → Implement rate limiting (in progress)
[3/5]   Add webhook handler
[4/5]   Set up monitoring
[5/5]   Write API docs
```

### Circuit breaker

Track these counters:
- `consecutive_stuck_items` — items where max fix attempts were exhausted
- `no_progress_iterations` — verify cycles with no file changes

Source and check the circuit breaker each iteration:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
source "$KOVA_LIB/circuit-breaker.sh"
circuit_breaker_check <consecutive_stuck> <no_progress>
```

If tripped (exit code 1): stop the loop, display reason, proceed to cleanup.

## Step 5: Cleanup (ALWAYS run)

Always clean up state, whether loop completed, was stopped early, or circuit breaker tripped:
```bash
KOVA_LIB="${CLAUDE_PLUGIN_ROOT:-$(pwd)/.claude}/hooks/lib"
[ -d "$KOVA_LIB" ] || KOVA_LIB="$(dirname "$(ls .claude/hooks/kova-loop.sh hooks/kova-loop.sh 2>/dev/null | head -1)")/lib"
source "$KOVA_LIB/kova-cleanup.sh"
kova_cleanup ".kova-loop"
echo "Cleanup done"
```

## Step 6: Report results

Report in this format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 KOVA LOOP — COMPLETE
 Items: X/Y completed | Stuck: Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/Y] ✓ Item description (commit abc1234)
[2/Y] ✓ Item description (commit def5678)
[3/Y] ✗ Item description (stuck — max fix attempts)
...
```

Then suggest next steps:
- **All done:** "All items implemented. Review the commits and push when ready."
- **Some stuck:** "Some items couldn't be completed. Review the stuck items and fix manually."
- **Circuit breaker:** "Loop stopped by circuit breaker. Simplify the stuck items or fix manually."

---

## Error handling

- If any helper script returns unexpected exit code (not 0 or 1): stop loop, display error, suggest `--mode=background` as fallback.
- If `kova_safe_commit` refuses (missing snapshot): re-run snapshot, then retry commit once.
- If bash sourcing fails: verify `KOVA_LIB` path and report the issue.

## Why this works

Hooks are **external enforcement** — Claude cannot bypass them:
1. **kova-commit-gate.sh** blocks commits without verification log
2. **verify-on-stop.sh** blocks early exit without passing lint/typecheck
3. **block-dangerous.sh** blocks destructive commands
4. **User watches in real-time** and can intervene at any point

Self-review is acknowledged as weaker than external `claude -p` review.
For stronger review, use `--mode=background` which runs a separate review session.
