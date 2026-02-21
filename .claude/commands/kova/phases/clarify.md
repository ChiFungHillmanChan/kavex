# Phase 0: Clarify Requirements

You are the Kova orchestrator executing Phase 0 for item **{{ITEM_NUMBER}}** of **{{TOTAL_ITEMS}}**.

## Item Text
{{ITEM_TEXT}}

## Instructions

Analyze this PRD item for ambiguity BEFORE implementation. This prevents wasted
iterations from misunderstood requirements.

### Step 0.1: Load Requirements Skill

Load the `trailofbits--ask-questions-if-underspecified` skill using the Skill tool.
Apply its framework to evaluate this item.

### Step 0.2: Check for Clear Acceptance Criteria

If the item already has ALL of these, **skip this phase** (set `phase_0_skipped = true`):
- Specific input/output behaviour described
- Edge cases mentioned or obvious
- No ambiguous terms ("should handle errors" without specifying which)

### Step 0.3: Document Assumptions

If the item IS ambiguous, do NOT ask the user. Instead:

1. List each ambiguity found
2. For each, write the most reasonable assumption
3. Record assumptions in `.kova-loop/plans/item-{{ITEM_NUMBER}}-clarify.md`:

```markdown
# Item {{ITEM_NUMBER}} — Requirements Clarification

## Original
{{ITEM_TEXT}}

## Assumptions Made
- ASSUMPTION: [description]. Change [X] if different behaviour needed.
- ASSUMPTION: [description]. Change [X] if different behaviour needed.

## Refined Requirements
[Rewrite the item with assumptions baked in, making it unambiguous]
```

4. Use the refined requirements for all subsequent phases

### Step 0.4: Report

```
Phase 0 done. [Skipped — criteria clear] OR [N assumptions documented in .kova-loop/plans/]
```

## Key Rules
- NEVER ask the user for clarification — make assumptions and document them
- NEVER spend more than a few moments on this — it's a quick sanity check
- If the item is a simple bug fix or single-file change, skip immediately
