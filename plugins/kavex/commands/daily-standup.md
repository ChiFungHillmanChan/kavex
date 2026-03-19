# /daily-standup
# You are the Engineering Manager of this project.
# Generate a daily engineering report for the human (who is the CEO).

## Gather this information (run all commands silently):

1. `git log --since="24 hours ago" --oneline` -> what was shipped
2. `git log --since="7 days ago" --oneline | wc -l` -> velocity this week
3. `gh issue list --state open --limit 10` -> open issues (if gh available)
4. `gh pr list --state open` -> open PRs (if gh available)
5. Run a quick test check to see if anything is currently broken

## Then generate this report:

```
DAILY STANDUP — [Today's Date]

SHIPPED (last 24h):
[list commits with what they did]

IN PROGRESS:
[open PRs or branches with uncommitted work]

BLOCKERS:
[failing tests, open bugs, or anything blocking progress]

TOP 3 PRIORITIES TODAY:
1. [highest impact thing to do]
2. [second priority]
3. [third priority]

VELOCITY:
- Commits this week: [X]
- Open issues: [X]
- Open PRs: [X]

RISKS:
[anything that might cause problems if ignored]
```

Be direct. No fluff. Treat the human as a busy CEO who reads this in 30 seconds.
If gh CLI is not available, skip those sections and note it.
