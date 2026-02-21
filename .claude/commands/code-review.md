# /code-review
# Multi-pass code review using subagents. Based on Boris Cherny's approach.
# Spawns parallel reviewers, then challenges their findings.

## Arguments: $ARGUMENTS
(If provided, review only that file/PR. Otherwise, review all staged changes.)

## Phase 1: Gather Diff
Run `git diff main` or `git diff --staged` to get the changes to review.

## Phase 2: Spawn 4 Parallel Review Subagents

Use subagents to run these 4 reviews simultaneously:

**Subagent A — Security Review:**
- Look for: hardcoded secrets, SQL injection, XSS, insecure dependencies, exposed API keys
- Check: auth/authorization logic, input validation, data sanitization

**Subagent B — Logic & Correctness Review:**
- Look for: off-by-one errors, null/undefined handling, race conditions, incorrect calculations
- Check: edge cases, error handling, return values

**Subagent C — Architecture & Patterns Review:**
- Look for: code duplication, violations of existing patterns, unnecessary complexity
- Check: separation of concerns, naming clarity, file organization

**Subagent D — Test Coverage Review:**
- Look for: untested code paths, missing edge case tests, tests that don't actually test anything
- Check: mock quality, test isolation, coverage of new code

## Phase 3: Challenge Findings (Second Pass)
Spawn 2 more subagents to poke holes in Phase 2 findings:
- Remove false positives ("this looks wrong but it's actually correct because...")
- Prioritize: HIGH / MEDIUM / LOW for each remaining issue

## Final Report Format:
```
CODE REVIEW REPORT

HIGH (must fix before merge):
- [file:line] [issue] -> [suggested fix]

MEDIUM (should fix soon):
- [file:line] [issue] -> [suggested fix]

LOW (nice to have):
- [file:line] [issue] -> [suggested fix]

LOOKS GOOD:
- [what was done well]

Verdict: APPROVE / APPROVE WITH COMMENTS / REQUEST CHANGES
```

After the report, ask: "Should I fix the HIGH issues now?"
If yes, use /fix-and-verify to resolve them.
