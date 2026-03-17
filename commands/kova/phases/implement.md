# Phase 2: Implement

You are the Kova orchestrator executing Phase 2 for item **{{ITEM_NUMBER}}** of **{{TOTAL_ITEMS}}**.

## Item Text
{{ITEM_TEXT}}

## Mode: {{MODE}}
- `implement` — New PRD item. Build it from the plan.
- `fix-verify` — Verification failed. Fix specific failures only.
- `fix-review` — Review found HIGH-severity issues. Fix them only.

## Instructions

### Step 2.1: Load Skills

**Always load (in order):**
1. `production-code-standards` skill via Skill tool
2. `superpowers:executing-plans` skill via Skill tool — follow its discipline for
   executing the plan from Phase 1 step-by-step

**Conditionally load (if item involves UI):**
Detect UI involvement by checking if item text or plan references any of:
`component`, `page`, `screen`, `button`, `form`, `modal`, `dialog`, `layout`,
`style`, `CSS`, `UI`, `UX`, `responsive`, `animation`, `theme`, `dark mode`

If UI detected:
- Load `ui-ux-pro-max` skill via Skill tool
- Note: `is_ui_item = true` (used in Phase 4 to trigger UX review)

**Check for other applicable superpowers skills:**
If the item involves debugging: load `superpowers:systematic-debugging`
If the item involves tests: load `superpowers:test-driven-development`

### Step 2.2: Execute Based on Mode

**If mode = "implement":**
1. Read the plan from `.kova-loop/plans/item-{{ITEM_NUMBER}}-plan.md` (if exists)
2. Read the clarification from `.kova-loop/plans/item-{{ITEM_NUMBER}}-clarify.md` (if exists)
3. Follow `superpowers:executing-plans` discipline: execute plan steps in order,
   checking off each step as completed, verifying incrementally
4. Write tests covering happy path, edge cases, and expected errors
5. Follow CLAUDE.md coding standards (300 line limit, no type-safety bypasses)
6. Track all changed files mentally for Phase 4 reviewers

**If mode = "fix-verify":**
1. Read the verification failures from `.kova-loop/current-failures.md`
2. Fix ONLY the specific failures listed — do NOT re-implement or refactor
3. If a test expectation is wrong (not the code), fix the test
4. Minimal changes only

**If mode = "fix-review":**
1. Read the HIGH-severity review findings from `.kova-loop/current-review.md`
2. Fix each HIGH issue without breaking existing tests
3. Security issues take priority
4. Do NOT fix MEDIUM/LOW — they are logged but do not block

### Step 2.3: Report

```
Phase 2 done. Mode: [implement|fix-verify|fix-review]. Changed N files.
```

## Key Rules
- NEVER skip writing tests in `implement` mode
- NEVER refactor or "improve" code in `fix-verify` mode — minimal fixes only
- NEVER fix MEDIUM/LOW review issues — only HIGH blocks
- Follow the plan from Phase 1 step-by-step using executing-plans discipline
- Apply ALL loaded skill standards to code written
- Load superpowers skills that match the work — don't ignore available capabilities
