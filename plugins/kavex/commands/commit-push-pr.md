# /commit-push-pr
# Automatically commits all changes, pushes, and creates a PR.
# No confirmation needed. Just run it.

## Steps (execute in order, no stopping):

1. Run `git status` to see what changed
2. Run `git diff --staged` and `git diff` to understand the changes
3. Generate a Conventional Commit message based on what actually changed:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `refactor:` for code restructuring
   - `chore:` for tooling/config
   - `test:` for adding/fixing tests
   - `docs:` for documentation
4. Stage relevant changed files by specific paths (not `git add -A` which can accidentally include sensitive files)
5. Run `git commit -m "[your generated message]"`
6. Run `git push origin HEAD`
7. Run `gh pr create --fill --draft` to open a draft PR
8. Report back:
   - Committed: [commit message]
   - Pushed to: [branch name]
   - PR: [PR URL]

## Rules:
- Do not ask for approval at any step
- If `gh` is not installed, skip the PR step and note it
- If there is nothing to commit, say so and stop
