# Phase 1: Plan

You are the Kova orchestrator executing Phase 1 for item **{{ITEM_NUMBER}}** of **{{TOTAL_ITEMS}}**.

## Item Text
{{ITEM_TEXT}}

## Instructions

Brainstorm approaches, map affected files, and produce an executable plan document.
Skip this phase for trivial single-file items.

### Step 1.1: Skip Check

If this item is trivial (single file, obvious change, no architectural decisions):
- Set `phase_1_skipped = true`
- Report: `Phase 1 skipped — trivial item.`
- Proceed to Phase 2

### Step 1.2: Load Skills

Load these skills via the Skill tool (in order):
1. `superpowers:brainstorming` — to explore approaches before committing to one
2. `superpowers:writing-plans` — to structure the plan document

### Step 1.3: Brainstorm

Apply the brainstorming skill to the item:
- Generate 2-3 possible approaches
- Evaluate trade-offs (complexity, risk, alignment with existing patterns)
- Pick the best approach and document WHY

### Step 1.4: Explore Codebase

Spawn an `Explore` subagent (read-only, sonnet model) via Task tool:

```
Explore the codebase to map files and patterns relevant to this task:
  [item text + refined requirements from Phase 0 if available]

Find:
1. Files that will need modification (list with line counts)
2. Existing patterns to follow (naming, structure, error handling)
3. Related tests that exist
4. Dependencies or imports that will be affected

Return a structured list. Do NOT modify any files.
```

### Step 1.5: Write Executable Plan

Apply the writing-plans skill. Create `.kova-loop/plans/item-{{ITEM_NUMBER}}-plan.md`:

```markdown
# Item {{ITEM_NUMBER}} — Implementation Plan

## Task
{{ITEM_TEXT}}

## Approach
[Selected approach from brainstorming, with reasoning]

## Files to Modify
- `path/to/file.ts` — [what changes]
- `path/to/test.ts` — [new tests needed]

## Implementation Steps
Each step should be independently executable:
1. [ ] [Step with specific file:function targets and what to do]
2. [ ] [Step — include enough detail for any agent to execute]
3. [ ] [Step — include test expectations]

## Patterns to Follow
- [Existing pattern observed in codebase, with file:line reference]

## Risks
- [Any non-obvious risk, or "none"]

## Execution
This plan can be executed by:
- **Kova Team Loop** — Phase 2 will read and execute these steps automatically
- **Manual** — A developer can follow the steps above independently
```

### Step 1.6: Report

```
Phase 1 done. Plan: N files, M steps. See .kova-loop/plans/item-N-plan.md
```

## Key Rules
- The Explore agent is READ-ONLY — it must not modify files
- Plans must be EXECUTABLE — each step has enough detail to act on without context
- Brainstorm BEFORE planning — don't skip the approach evaluation
- Skip for obvious items (rename, config change, single function)
