# Kova Configuration Guide

Common configuration tasks for Kova, with the exact file and line to change.

---

## I want to change the max iterations

The Team Loop defaults to **20 iterations**. To change it:

**Option A: CLI flag (per-run)**

```bash
bash hooks/kova-loop.sh my-prd.md --max-iterations 10
```

**Option B: Edit the default in `hooks/kova-loop.sh`**

Find this line near the top:

```bash
MAX_ITERATIONS=20
```

Change `20` to your preferred limit.

> You can also set `--max-fix-attempts N` to control how many times Kova retries a single stuck item (default: 5).

---

## I want to skip the stop gate

The stop gate runs lint + typecheck every time Claude stops. To bypass it:

**Option A: Environment variable (temporary)**

```bash
KOVA_LOOP_ACTIVE=1 claude
```

When `KOVA_LOOP_ACTIVE=1` is set, the stop gate knows it is inside a loop iteration and skips the interactive check.

**Option B: Disable all hooks**

```bash
kova deactivate
```

This turns off every Kova hook (stop gate, file protection, command blocking, auto-format). Re-enable with `kova activate`.

---

## I want to protect additional files

Edit `hooks/protect-files.sh`. There are two arrays:

**Exact basename match** (for filenames like `.env`):

```bash
PROTECTED_BASENAME=(
  ".env"
  ".env.local"
  # Add your file here:
  ".env.custom"
)
```

**Substring match on full path** (for directories or extensions):

```bash
PROTECTED_SUBSTRING=(
  "secrets/"
  ".pem"
  # Add your pattern here:
  "internal-keys/"
)
```

Basename match prevents false positives (e.g. `some.environment.ts` will not match `.env`). Substring match catches patterns anywhere in the path.

---

## I want to block additional commands

Edit `hooks/block-dangerous.sh`. Find the `BLOCKED_PATTERNS` array:

```bash
BLOCKED_PATTERNS=(
  "rm -rf /"
  "DROP TABLE"
  # Add your pattern here:
  "kubectl delete namespace"
)
```

Patterns are matched case-insensitively using substring search. Kova also normalizes quotes and backslash escapes before matching, so obfuscated variants are caught automatically.

To add a **warning** instead of a hard block, add to the `WARN_PATTERNS` array lower in the same file:

```bash
WARN_PATTERNS=(
  "rm -rf"
  "force-with-lease"
  "your-pattern-here"
)
```

---

## I want to add Codex cross-model review

Kova auto-detects Codex availability. You just need to install it and set your API key.

**Step 1: Install Codex CLI globally**

```bash
npm install -g @openai/codex
```

**Step 2: Set your API key**

```bash
export OPENAI_API_KEY="sk-..."
```

Add this to your shell profile (`.zshrc`, `.bashrc`) to persist it.

That's it. Kova's `hooks/lib/codex-assist.sh` calls `command -v codex` at runtime. When available, Codex is used for cross-model diagnosis after repeated failures and for code review.

You can also set `CODEX_TIMEOUT` (default: 120 seconds) to control how long Kova waits for a Codex response.

---

## I want to change the rate limit

Set the `MAX_INVOCATIONS_PER_HOUR` environment variable:

```bash
export MAX_INVOCATIONS_PER_HOUR=50
```

The default is **100** invocations per rolling hour. When the limit is hit, Kova pauses with a countdown and resumes automatically once the oldest invocation ages out of the window.

---

## I want to add a custom formatter

Edit `hooks/format.sh`. This hook runs after every Write/Edit operation. Add a new case to the `case "$EXT" in` block:

```bash
  swift)
    if command -v swiftformat &>/dev/null; then
      swiftformat "$FILE" 2>/dev/null || true
    fi
    ;;
```

The pattern is always the same:
1. Match the file extension
2. Check if the formatter command exists
3. Run it with `2>/dev/null || true` so failures never block Claude

Existing formatters: Prettier (JS/TS/CSS/HTML/MD/YAML), Ruff/Black (Python), gofmt (Go), rustfmt (Rust), RuboCop (Ruby), google-java-format (Java), dotnet format (C#), taplo (TOML), jq (JSON).

---

## I want to use dry-run mode

Pass `--dry-run` to preview what the Team Loop would do without executing anything:

```bash
bash hooks/kova-loop.sh my-prd.md --dry-run
```

This parses the PRD, detects your stack, prints the item list and config, then exits with no changes. Useful for verifying your PRD is parsed correctly before a real run.
