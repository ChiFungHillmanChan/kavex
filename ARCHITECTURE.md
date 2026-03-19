# Kavex Architecture

## Overview

Kavex is a **bash-enforced engineering protocol** for Claude Code. The core principle:

> **Claude is the worker. Bash is the boss.**

Claude Code supports a hook system that intercepts tool calls (file writes, bash commands, stop events) before and after they execute. Kavex registers hooks via `hooks.json` that run shell scripts at these interception points. Because hooks run outside Claude's context — in a separate bash process — Claude cannot skip, modify, or argue its way out of verification.

This is not prompt engineering. It is **process enforcement**.

---

## Hook Execution Flow

Claude Code's hook system pipes tool-call metadata as JSON to hook scripts via stdin. Each hook script reads the JSON, inspects it, and returns a decision.

```
  Claude invokes a tool (Bash, Write, Edit, Stop)
         |
         v
  +------------------+
  |   hooks.json     |  Matcher selects which hooks fire
  |   (matcher)      |  e.g. "Bash", "Write|Edit|MultiEdit", "Stop"
  +--------+---------+
           |
           v
  +------------------+
  | PreToolUse hook  |  Runs BEFORE the tool executes
  |  (stdin: JSON)   |
  +--------+---------+
           |
     +-----+------+
     |            |
   ALLOW        BLOCK
     |         (exit 2, prints reason)
     v
  +------------------+
  |  Tool executes   |
  +--------+---------+
           |
           v
  +------------------+
  | PostToolUse hook  |  Runs AFTER the tool executes
  |  (e.g. format.sh)|
  +------------------+
```

### Registered Hooks

```
PreToolUse:
  Bash           -> block-dangerous.sh    Block rm -rf /, DROP TABLE, force push, etc.
                 -> kavex-commit-gate.sh   Block git commit without verification proof
  Write|Edit     -> protect-files.sh      Block writes to .env, credentials, etc.

PostToolUse:
  Write|Edit     -> format.sh            Auto-format written files (Prettier, Ruff, gofmt, etc.)

Stop:
  (all)          -> verify-on-stop.sh     Fast gate: lint + typecheck before Claude stops
```

---

## 7-Layer Verification

The verification gate (`verify-gate.sh`) runs up to 7 layers of checks. Each layer auto-detects the project stack (Node.js, Python, Go, Rust, Ruby, Java, .NET) and runs the appropriate tool.

```
  Layer   Check                What runs                        On failure
  -----   ------------------   ------------------------------   ----------
  [1]     Build / Compile      npm run build, go build,         FAIL
                               cargo build, mvn compile, etc.
  [2]     Unit Tests           jest, vitest, pytest, go test,   FAIL
                               cargo test (with flaky retry)
  [3]     Integration Tests    npm run test:integration         FAIL
                               (with flaky retry)
  [4]     E2E Tests            Playwright                       FAIL
                               (with flaky retry)
  [5]     Lint                 eslint, ruff, clippy,            FAIL
                               golangci-lint, rubocop
  [6]     Type Check           tsc --noEmit, mypy, pyright,     FAIL
                               go vet, cargo check
  [7]     Security Audit       npm audit, pip-audit,            WARN only
                               cargo audit, govulncheck
```

**Flaky retry:** Layers 2-4 (test layers) automatically retry once on failure before reporting a hard fail. This handles transient test flakiness without masking real failures.

**Security audit (Layer 7):** Reports vulnerabilities but does not fail the gate. This is intentional — security advisories often have no immediate fix and should not block development.

### What Runs Where

| Context         | Layers Run | Purpose                                    |
|-----------------|------------|--------------------------------------------|
| **Stop hook**   | 5-6 only   | Fast gate — catch lint/type errors on stop  |
| **Team Loop**   | 1-7 all    | Full verification per iteration             |
| **Commit gate** | N/A        | Checks for verification proof file, not layers |

The stop hook runs layers 5-6 only because build and test suites can take minutes. Running them on every stop would make Claude unusable. The Team Loop runs all 7 because it operates autonomously and correctness matters more than speed.

---

## Team Loop State Machine

The Team Loop (`kavex-loop.sh`) iterates over items in a PRD file. Each item goes through a state machine:

```
                        +------------------+
                        |   Parse PRD      |
                        |   Extract items  |
                        +--------+---------+
                                 |
                    For each item (i = 1..N):
                                 |
                                 v
                  +-----------------------------+
                  |       IMPLEMENT              |
                  |  claude -p (separate session)|
                  |  "Implement item i"          |
                  +-------------+---------------+
                                |
                                v
                  +-----------------------------+
              +-->|         VERIFY               |
              |   |  verify-gate.sh (all 7)      |
              |   +-------------+---------------+
              |                 |
              |          pass?--+--fail
              |                 |      |
              |                 |      v
              |                 |  +-------------------+
              |                 |  | DIAGNOSE + RETRY  |
              |                 |  | Parse failures     |
              |                 |  | claude -p "fix X"  |
              |                 |  +--------+----------+
              |                 |           |
              |                 |   max attempts?
              |                 |     no --+-- yes --> circuit breaker
              |                 |          |
              +<---------------+-----------+
                                |
                          pass  |
                                v
                  +-----------------------------+
              +-->|         REVIEW               |
              |   |  run-code-review.sh          |
              |   |  (separate claude -p session)|
              |   +-------------+---------------+
              |                 |
              |          clean?-+--HIGH issues
              |            or   |      |
              |           low   |      v
              |                 |  +-------------------+
              |                 |  | FIX HIGH ISSUES   |
              |                 |  | claude -p "fix"   |
              |                 |  +--------+----------+
              |                 |           |
              +<----------------+-----------+
                                |
                          clean/low
                                v
                  +-----------------------------+
                  |         COMMIT               |
                  |  git add + git commit        |
                  +-----------------------------+
                                |
                                v
                        Next item or DONE
```

**Context isolation:** Each `claude -p` invocation is a separate session. This prevents context pollution between iterations and keeps token usage bounded. A 20-item PRD runs 20+ independent Claude sessions, each with a focused prompt.

**Circuit breaker:** If an item fails verification `MAX_FIX_ATTEMPTS` times (default: 5), the loop writes a failure report and moves to the next item rather than looping forever.

---

## Trust Model

Kavex's trust model is based on **boundary enforcement**:

```
  +---------------------------------------------+
  |  Claude's context                            |
  |                                              |
  |  Can: write code, run commands, reason       |
  |  Cannot: bypass hooks (they run outside)     |
  |                                              |
  +---------------------+--+--------------------+
                        |  ^
              tool call |  | allow/block
                        v  |
  +---------------------------------------------+
  |  Hook boundary (bash)                        |
  |                                              |
  |  Reads tool-call JSON via stdin              |
  |  Decides: allow, block, or warn              |
  |  Runs AFTER Claude exits (stop hook)         |
  |  Runs BEFORE tool executes (pre-tool hooks)  |
  +---------------------------------------------+
```

Key properties:

1. **Claude cannot skip verification.** The stop hook runs after Claude finishes. In the Team Loop, `verify-gate.sh` runs from bash after the `claude -p` process exits. There is no prompt Claude can craft to avoid it.

2. **jq failure = fail-closed.** Hooks parse tool-call JSON with `jq`. If `jq` is missing or parsing fails, the hook blocks the operation rather than silently allowing it. This prevents bypass via malformed input.

3. **User can disable hooks.** This is by design, not a bug. Kavex enforces engineering discipline, not security policy. The user is trusted; Claude is instrumented.

4. **Verification proof is required for commits.** The commit gate (`kavex-commit-gate.sh`) checks for a proof file written by `verify-gate.sh`. Without this file, `git commit` is blocked. The proof file is timestamped and project-scoped to prevent replay.

5. **Bypass detection.** Hooks check for known bypass patterns (e.g., piping through `sh`, base64 encoding commands, using `env` to circumvent PATH restrictions). Detected bypass attempts are blocked with an explanation.

---

## Key Design Decisions

### Why bash over prompt orchestration

Previous versions used prompt instructions to tell Claude to run verification. Claude skipped them — sometimes due to context length, sometimes due to reasoning shortcuts. Bash orchestration is **unskippable** because verification runs in a separate process after Claude exits.

### Why `mktemp` for temp directories

Kavex creates temporary directories for verification output, proof files, and lock files. Using `mktemp -d` (with mode 700) prevents **symlink attacks** where an attacker pre-creates a predictable temp path as a symlink to a sensitive location. `mktemp` generates unpredictable names and creates the directory atomically.

### Why `mkdir` for locks

The Team Loop uses `mkdir` as a concurrency lock (`mkdir "$LOCK_DIR" 2>/dev/null`). This is preferred over file-based locks because `mkdir` is **atomic on POSIX** — it either creates the directory and succeeds, or the directory exists and it fails. No race condition between check and create.

### Why separate `claude -p` sessions per iteration

Each PRD item gets its own `claude -p` session for three reasons:

1. **Context isolation** — failures in item 3 don't pollute the context when working on item 4
2. **Token budget** — long-running sessions accumulate context and hit limits; fresh sessions start clean
3. **Failure containment** — if a session crashes or hangs, only one item is affected

### Why the stop hook runs layers 5-6 only

Build and test suites can take minutes. Running all 7 layers on every `Stop` event would make interactive Claude Code sessions painfully slow. Layers 5-6 (lint + typecheck) are fast (seconds) and catch the most common issues. Full verification runs in the Team Loop where latency is acceptable.

### Why security audit is warn-only

Security advisories (`npm audit`, `pip-audit`, etc.) frequently report vulnerabilities in transitive dependencies with no available fix. Failing the gate on these would block all development until upstream patches land. Warning surfaces the information without blocking progress.
