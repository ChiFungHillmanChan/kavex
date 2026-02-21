# /kova:loop
# Kova Team Loop — implement PRD items with engineering-team quality.
# Each item: clarify → plan → implement → verify → independent-review → commit.
# Phases are dispatched from .claude/commands/kova/phases/*.md
#
# Usage: /kova:loop <prd-file> [--dry-run] [--no-commit] [--max-iterations N] [--max-fix-attempts N]

You are now the Kova Team Loop orchestrator. Follow these steps EXACTLY.

---

## Phase A: Validate & Parse

### A.1 Get the PRD file path

The user argument is: `$ARGUMENTS`

- If `$ARGUMENTS` is empty or blank, say:
  ```
  Usage: /kova:loop <prd-file>
  Example: /kova:loop docs/prd-auth.md
  No PRD file specified. Run /kova:init to scaffold a new PRD file.
  ```
  Then STOP.

- Parse flags from `$ARGUMENTS`:
  - `--dry-run` → DRY_RUN mode (parse and show plan, don't execute)
  - `--no-commit` → skip git commit after each item
  - `--max-iterations N` → override default 20
  - `--max-fix-attempts N` → override default 5
  - Remaining non-flag argument is the PRD file path

### A.2 Validate prerequisites

Run these checks via Bash. If ANY fail, report and STOP:

```bash
test -f "<prd-file>" && echo "PRD_OK" || echo "PRD_MISSING"
command -v jq &>/dev/null && echo "JQ_OK" || echo "JQ_MISSING"
git rev-parse --is-inside-work-tree 2>/dev/null && echo "GIT_OK" || echo "GIT_MISSING"
git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null && echo "GIT_CLEAN" || echo "GIT_DIRTY"
test -f ".claude/hooks/lib/detect-stack.sh" && echo "LIB_OK" || echo "LIB_MISSING"
```

- `PRD_MISSING` → "PRD file not found: `<path>`. Check the path."
- `JQ_MISSING` → "jq required. Run: `brew install jq` (macOS) or `apt install jq`"
- `GIT_MISSING` → "Not a git repo. The loop needs git for commits."
- `GIT_DIRTY` → WARNING only: "Uncommitted changes exist. Consider committing first."
- `LIB_MISSING` → "Kova lib not found. Run `/kova:install` first."

### A.3 Parse the PRD file

Read the PRD file. Determine format:

**Markdown:** Extract `- [ ] ` lines as pending. `- [x] ` lines are completed (context only).
**JSON:** Extract items from `{ "items": [...] }`. `"done": true` items are completed.

If format unrecognized or no pending items, report and STOP.

### A.4 Check for existing loop state

```bash
test -d ".kova-loop" && echo "STATE_EXISTS" || echo "NO_STATE"
```

If `.kova-loop/` exists, read `.kova-loop/LOOP_PROGRESS.md`, show it, and ask:
`resume` / `restart` / `cancel`. Wait for input.

### A.5 Show plan and confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 KOVA TEAM LOOP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PRD:             <filename> (<N> pending, <M> completed)
 Max iterations:  20
 Max fix tries:   5 per item
 Auto-commit:     yes/no
 Cycle:           clarify → plan → implement → verify → review (+ Codex if available) → commit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 Items to implement:
  1. [ ] <item 1>
  2. [ ] <item 2>
  ...

 Already completed:
  [x] <completed item>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If `--dry-run`, show the above and STOP.
Otherwise ask: **"Ready to start. Type `go` to begin."** Wait for confirmation.

---

## Phase B: The Loop

Initialize:
```bash
mkdir -p .kova-loop/plans
```

Create `.kova-loop/LOOP_PROGRESS.md` with initial state.

### B.0: Discover project agents

Read `.claude/agents/*.md` using Glob. For each agent file, read its description.
Build a map of `agent_name → role` for use in Phase 4 (review) and Phase 5 (commit).
This makes the loop portable — it adapts to whatever agents the project has installed.

If `.claude/agents/` is empty or missing, all phases fall back to `general-purpose`.

Track mentally: `current_item`, `iteration`, `fix_attempts`, `mode`, `is_ui_item`,
`completed_items`, `stuck_items`, `discovered_agents`.

### For each iteration:

**Exit conditions** (check FIRST):
- `current_item > total_items` → Phase C
- `iteration >= max_iterations` → Phase C
- User sends "stop" or "cancel" → Phase C

Increment `iteration`. Then dispatch the current phase:

---

### B.1: Phase dispatch (based on mode)

**If mode = "implement"** (new item):

1. **Phase 0 — Clarify:** Read `.claude/commands/kova/phases/clarify.md` and execute.
   Replace `{{ITEM_NUMBER}}`, `{{TOTAL_ITEMS}}`, `{{ITEM_TEXT}}` with actual values.

2. **Phase 1 — Plan:** Read `.claude/commands/kova/phases/plan.md` and execute.
   Skip if item is trivial (single file, obvious change).

3. **Phase 2 — Implement:** Read `.claude/commands/kova/phases/implement.md` and execute
   with `MODE = "implement"`.

4. **Phase 3 — Verify:** Read `.claude/commands/kova/phases/verify.md` and execute.

5. **Branch on verify result:**
   - PASS → go to Phase 4 (review)
   - FAIL → set `mode = "fix-verify"`, `fix_attempts += 1`, continue loop

6. **Phase 4 — Review:** Read `.claude/commands/kova/phases/review.md` and execute.

7. **Branch on review result:**
   - PASS (no HIGH) → go to Phase 5 (commit)
   - HIGH found → set `mode = "fix-review"`, `fix_attempts += 1`, continue loop

8. **Phase 5 — Commit:** Read `.claude/commands/kova/phases/commit.md` and execute.
   Record commit hash. Set `current_item += 1`, `fix_attempts = 0`, `mode = "implement"`.

**If mode = "fix-verify":**
- Execute Phase 2 with `MODE = "fix-verify"`, then Phase 3.
- On PASS → Phase 4 (review). On FAIL → increment `fix_attempts`, retry.

**If mode = "fix-review":**
- Execute Phase 2 with `MODE = "fix-review"`, then Phase 3, then Phase 4.
- On PASS → Phase 5. On HIGH → increment `fix_attempts`, retry.

### B.2: Stuck detection

If `fix_attempts >= max_fix_attempts`:
```
  STUCK on item <N> after <max> attempts. Skipping.
```
- Add to `stuck_items` with last failure details
- Write to `.kova-loop/STUCK_ITEMS.md`
- Set `current_item += 1`, `fix_attempts = 0`, `mode = "implement"`

### B.3: Update progress

After every iteration, update `.kova-loop/LOOP_PROGRESS.md`:
```markdown
# Kova Team Loop Progress
Started: <date> | PRD: <file> (<N> items)

- [x] 1. <item> (commit abc1234)
- [ ] 3. <item> (IN PROGRESS, fix attempt 2/5)
- [ ] 4. <item>

Stats: 7/20 iterations | 2/5 items done | mode: fix-verify
```

Append to `.kova-loop/ITERATION_LOG.md`:
```markdown
## Iteration <N> — Item <M> — Mode: <mode>
Result: <PASS|FAIL|DONE|STUCK>
Detail: <what happened>
---
```

### B.4: Brief status to user

```
Iteration <N>. Item <M>/<total>: <PASS|FAIL|DONE|STUCK>. <one sentence>.
```
Do NOT wait for user input — keep going. Check for "stop"/"cancel".

---

## Phase C: Report Results

Read `.kova-loop/LOOP_PROGRESS.md` and display it. Then:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 KOVA TEAM LOOP — COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Items completed: <X>/<Y>
 Iterations used: <N>/<max>
 Stuck items:     <Z>
 Commits:         <list>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Suggest next steps based on outcome:
- **All done:** `/verify-app` for full QA, then `/commit-push-pr` to ship.
- **Some stuck:** See `.kova-loop/STUCK_ITEMS.md`. Fix manually and re-run.
- **Hit limit:** Re-run with `--max-iterations 40` to continue.
- **Cancelled:** Progress saved. Re-run to resume.

---

## Key Rules (NEVER violate)

1. **NEVER use `--dangerously-skip-permissions`**
2. **NEVER skip verification** — every implementation/fix MUST pass Phase 3
3. **NEVER blind retry** — every fix uses specific file:line diagnostics
4. **NEVER commit failing code** — only after Phase 3 pass AND Phase 4 pass
5. **ALWAYS update progress** — `.kova-loop/LOOP_PROGRESS.md` after every iteration
6. **ALWAYS dispatch phases by reading the phase file** — do not inline phase logic
7. **ALWAYS launch Phase 4 reviewers in parallel** — single message, multiple Task calls
8. **ALWAYS respect stuck limit** — skip after max fix attempts
9. **ALWAYS discover agents from `.claude/agents/`** — never hardcode agent names
10. **ALWAYS load superpowers skills** when they match the work (brainstorming,
    executing-plans, writing-plans, requesting-code-review, etc.)
