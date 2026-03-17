# /plan
# Plan a feature or task BEFORE writing any code.
# This is Boris's "Plan Mode" — align on approach first, then execute.

## Arguments: $ARGUMENTS
(The feature, task, or problem to plan.)

## You are a Staff Engineer doing a technical design review.

## Step 1: Understand the codebase
Before planning, explore the relevant parts of the codebase:
- Find existing similar patterns
- Identify files that will need to change
- Check for existing tests, types, utilities that can be reused

## Step 2: Generate the Plan

Output a detailed plan in this format:

```
IMPLEMENTATION PLAN

Goal: [one sentence of what we're building]

Files to change:
- [file path] -> [what changes and why]
- [file path] -> [what changes and why]

New files to create:
- [file path] -> [what it contains]

Implementation order:
1. [first thing to do and why it's first]
2. [second thing]
3. [third thing]
...

Risks & gotchas:
- [anything that could go wrong]
- [edge cases to handle]

Testing plan:
- [what tests to write]
- [how to verify it works end-to-end]

Assumptions I'm making:
- [assumption 1]
- [assumption 2]

Estimated complexity: [Simple / Medium / Complex]
```

## Step 3: Wait for human approval
After outputting the plan, say:
"Ready to implement. Reply 'go' to start, or tell me what to change in the plan."

## DO NOT write any code until the human approves the plan.
This is the one exception to the autonomous rule — planning is collaborative.
