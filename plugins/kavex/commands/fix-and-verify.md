# /fix-and-verify
# You have a bug or failing test. Fix it completely. Do not come back until it's green.

## Arguments: $ARGUMENTS
(If arguments provided, focus on that specific bug/test. Otherwise, find and fix all failures.)

## Process:

### Phase 1: Diagnose
1. Run the full test suite to see ALL failures at once
2. For each failure, identify the ROOT CAUSE (not just the symptom)
3. Group related failures (often one root cause breaks many tests)

### Phase 2: Fix
For each root cause:
1. Fix the actual problem, not just the test
2. If the test itself is wrong, fix the test AND explain why
3. Add a regression test that would have caught this bug

### Phase 3: Verify
1. Run full test suite -> must be 100% green
2. Run lint -> must be clean
3. Run typecheck -> must be clean
4. Check no new console.log or debug code was left in

### If Stuck (same failure after 3 attempts):
Create `DEBUG_LOG.md` with:
```
## Bug: [description]
## Attempts:
1. Tried: [what you tried] -> Result: [what happened]
2. Tried: [what you tried] -> Result: [what happened]
3. Tried: [what you tried] -> Result: [what happened]
## Current state: [exact error message]
## Suspected cause: [your best guess]
## What I need: [what info or decision you need from the human]
```
Then stop and ask the human.

## Final Report:
```
Bug Fixed
---
Root cause: [what was actually wrong]
Fix applied: [what you changed and why]
Regression test: [what test now covers this]
---
All tests passing
No new issues introduced
```
