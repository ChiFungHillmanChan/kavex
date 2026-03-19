# FAQ

## Why bash orchestration instead of prompt-based self-orchestration?

Prompt-based enforcement relies on Claude obeying instructions, but prompt compliance can be skipped — Claude may decide to skip verification or review phases entirely. With bash orchestration, `kavex-loop.sh` runs verification *after* Claude exits its session. Since Claude has already exited, it cannot skip the verification step. Bash is the boss; Claude is the worker.

## What languages and stacks are supported?

Kavex supports **Node.js, Python, Go, Rust, Ruby, Java, and .NET**. The stack is auto-detected by `detect-stack.sh`, which looks for signature files in your project (e.g., `package.json` for Node.js, `Cargo.toml` for Rust, `go.mod` for Go). The verification gate and auto-formatter automatically use the correct tools for your detected stack.

## What is the difference between the `kavex` and `kavex-full` plugins?

| Plugin | What you get |
|--------|-------------|
| **kavex** | Slash commands (`/plan`, `/verify-app`, `/code-review`, etc.) + engineering protocol skill |
| **kavex-full** | Everything in `kavex` plus safety hooks, verification gate, auto-format, commit gate, and the Team Loop |

Choose `kavex` if you want the workflow commands without enforcement. Choose `kavex-full` if you want the full autonomous engineering system with bash-orchestrated hooks.

## How does Kavex compare to Ralph?

[Ralph](https://github.com/frankbria/ralph-claude-code) inspired the bash orchestrator pattern — the idea that bash should control the loop, not prompts. Kavex builds on this foundation and adds: 7-layer verification gate, circuit breaker for stuck loops, multi-model review (Claude + optional Codex), resumable state saved in `.kavex-loop/`, rate limiting, and a tmux monitoring dashboard.

## Does Kavex work with OpenAI Codex?

Codex integration is **optional**. If you have `@openai/codex` installed, Kavex can use `codex-assist.sh` for cross-model code review — a second opinion from a different model. This is not required for any core functionality. Kavex works fully with Claude Code alone.

## What happens if `jq` is missing?

Hooks **block operations for safety** (fail-closed design). Rather than silently allowing potentially dangerous operations without proper JSON parsing, Kavex refuses to proceed. Install `jq` to resolve this: `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu), or `dnf install jq` (Fedora).

## Can the hooks be bypassed?

Yes, and this is by design. The user is always in control. You can disable hooks via `kavex deactivate` or by editing your `settings.json` to remove hook entries. Kavex enforces discipline during active sessions — it does not lock you out of your own tools. To re-enable, run `kavex activate`.

## How do I add support for a new language?

1. Edit `detect-stack.sh` to add detection logic for your language (e.g., check for a signature file like `mix.exs` for Elixir).
2. Edit `verify-gate.sh` to add the corresponding build, test, lint, and typecheck commands for that language.
3. Optionally update the auto-format hook if your language has a standard formatter.

## Is Kavex safe for production environments?

Kavex is a **development-time tool only**. Hooks run exclusively inside Claude Code sessions — they do not execute in CI/CD pipelines, production deployments, or anywhere outside of Claude Code. Kavex instruments your development workflow; it does not touch your production systems.

## How do I disable specific hooks without deactivating everything?

Edit `hooks.json` or your project's `settings.json` to remove or comment out specific hook entries. For example, you can keep the commit gate active while disabling the stop hook, or vice versa. Run `kavex status` afterward to confirm which hooks are active.

## What is the difference between the Stop hook and the Team Loop?

The **Stop hook** (`verify-on-stop.sh`) is a fast gate that runs **lint + typecheck** every time Claude stops. It catches basic errors quickly. The **Team Loop** (`kavex-loop.sh`) is the full autonomous workflow that runs **7-layer verification** (build, test, lint, typecheck, security, etc.) for each PRD item, plus code review and automatic commit. The Stop hook is a safety net; the Team Loop is the full engineering process.

## Can I resume a Team Loop after interruption?

Yes. The Team Loop saves its state in the `.kavex-loop/` directory, including which PRD items have been completed, verification results, and review status. If the loop is interrupted (e.g., by a crash, network issue, or manual stop), simply re-run the same `/kavex:loop` command. It will pick up where it left off.
