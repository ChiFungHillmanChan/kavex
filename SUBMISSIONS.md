# Awesome List Submissions

Tracking Kova submissions to curated awesome lists. Each entry includes the target repo, category, submission status, and PR content.

## Submission Status

| # | Repository | Stars | Category | Status |
|---|-----------|-------|----------|--------|
| 1 | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 24.7k | Hooks / Orchestrators | `pending` |
| 2 | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 37.0k | Workflow Automation | `pending` |
| 3 | [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | 11.1k | Orchestration / QA | `pending` |
| 4 | [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | 7.5k | Workflow Enforcement | `pending` |
| 5 | [rohitg00/awesome-claude-code-toolkit](https://github.com/rohitg00/awesome-claude-code-toolkit) | 541 | Hooks | `pending` |
| 6 | [BehiSecc/awesome-claude-skills](https://github.com/BehiSecc/awesome-claude-skills) | 6.2k | Development Tools | `pending` |
| 7 | [ccplugins/awesome-claude-code-plugins](https://github.com/ccplugins/awesome-claude-code-plugins) | 488 | Hooks | `pending` |
| 8 | [ComposioHQ/awesome-claude-plugins](https://github.com/ComposioHQ/awesome-claude-plugins) | 1.3k | Hooks / Plugins | `pending` |
| 9 | [e2b-dev/awesome-ai-agents](https://github.com/e2b-dev/awesome-ai-agents) | 26.0k | Agent Infrastructure | `pending` |
| 10 | [Prat011/awesome-llm-skills](https://github.com/Prat011/awesome-llm-skills) | 927 | Agent Workflow Tools | `pending` |
| 11 | [tonysurfly/awesome-claude](https://github.com/tonysurfly/awesome-claude) | 1.1k | Tools | `pending` |
| 12 | [tensorchord/Awesome-LLMOps](https://github.com/tensorchord/Awesome-LLMOps) | 5.6k | LLM DevOps | `pending` |

## How to Submit

Run the helper script to fork, create a branch, and open a PR for each list:

```bash
./scripts/submit-to-awesome-lists.sh <number>
# e.g., ./scripts/submit-to-awesome-lists.sh 1   # submits to awesome-claude-code
```

Or manually fork each repo and add the appropriate entry (see PR content below).

---

## PR Content Per Repository

### 1. hesreallyhim/awesome-claude-code

**Target section:** Hooks (or Orchestrators under Tooling)

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Autonomous engineering protocol with bash-enforced verification. 7-layer verification gate, self-healing loops, and commit blocking — because prompts can be skipped, but bash hooks can't.
```

**PR title:** `Add Kova — bash-enforced verification hooks and orchestrator`
**PR body:** Kova is a bash-based enforcement layer for Claude Code that adds 7-layer verification gates, a self-healing loop orchestrator, and commit blocking hooks. Unlike prompt-based approaches, bash hooks can't be skipped. 193 tests, 7 language support.

---

### 2. ComposioHQ/awesome-claude-skills

**Target section:** Workflow Automation / Development Tools

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Bash-enforced autonomous engineering protocol. Drops into any project to add verification gates, self-healing loops, and commit safety — turning Claude Code from assistant into engineering system.
```

**PR title:** `Add Kova — bash-enforced verification workflow for Claude Code`

---

### 3. VoltAgent/awesome-claude-code-subagents

**Target section:** Orchestration / Quality Assurance

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Bash orchestrator that drives Claude Code subagent sessions through verification-gated development loops. Spawns `claude -p` per iteration with 7-layer quality gates between each step.
```

**PR title:** `Add Kova — bash orchestrator for verification-gated subagent loops`

---

### 4. travisvn/awesome-claude-skills

**Target section:** Workflow / Enforcement

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Autonomous engineering protocol with bash-enforced verification. Adds CLAUDE.md standards, hook-based safety nets, and a self-healing development loop.
```

**PR title:** `Add Kova — bash-enforced engineering protocol and verification skills`

---

### 5. rohitg00/awesome-claude-code-toolkit

**Target section:** Hooks

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Complete hook-based enforcement system: verify-on-stop (Stop hook), commit-gate (PreToolUse hook), and bash orchestrator loop. 7-layer verification covering build, test, lint, typecheck, and more across 7 languages.
```

**PR title:** `Add Kova — comprehensive hook-based verification toolkit`

---

### 6. BehiSecc/awesome-claude-skills

**Target section:** Development Tools

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Bash-enforced autonomous engineering protocol for Claude Code. 7-layer verification, self-healing loops, and commit safety hooks.
```

**PR title:** `Add Kova — bash-enforced verification for Claude Code`

---

### 7. ccplugins/awesome-claude-code-plugins

**Target section:** Hooks

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Hook-based enforcement system with verify-on-stop, commit-gate, and bash-orchestrated development loops. Prevents Claude from stopping without passing tests or committing unverified code.
```

**PR title:** `Add Kova — hook-based verification enforcement`

---

### 8. ComposioHQ/awesome-claude-plugins

**Target section:** Hooks / Plugins

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Autonomous engineering protocol with bash-enforced verification hooks. Stop hooks prevent early exit, PreToolUse hooks block unverified commits, and a bash orchestrator drives the development loop.
```

**PR title:** `Add Kova — bash-enforced verification hooks`

---

### 9. e2b-dev/awesome-ai-agents

**Target section:** Developer Tools / Agent Infrastructure

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Bash-enforced autonomous engineering protocol for Claude Code. Orchestrates AI coding agent sessions through verification-gated loops with self-healing, ensuring code quality without human intervention.
```

**PR title:** `Add Kova — verification-gated orchestrator for AI coding agents`

---

### 10. Prat011/awesome-llm-skills

**Target section:** Agent Workflow Tools

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Bash-enforced verification protocol for Claude Code. 7-layer quality gates, self-healing loops, and commit safety — works with any project, any language.
```

**PR title:** `Add Kova — bash-enforced verification for LLM coding agents`

---

### 11. tonysurfly/awesome-claude

**Target section:** Tools

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Autonomous engineering protocol with bash-enforced verification for Claude Code. Drops into any project to add safety hooks, verification gates, and self-healing development loops.
```

**PR title:** `Add Kova — bash-enforced engineering protocol for Claude Code`

---

### 12. tensorchord/Awesome-LLMOps

**Target section:** Quality / Testing / DevOps

**Entry to add:**

```markdown
- [Kova](https://github.com/ChiFungHillmanChan/kova) - Bash-enforced verification protocol for AI coding agents. 7-layer quality gates (build, test, lint, typecheck, security, coverage, integration) with self-healing loops — the CI/CD equivalent for LLM-driven development.
```

**PR title:** `Add Kova — verification gates for LLM-driven development`

---

## Submission Priority

**Tier 1 — Submit immediately (highest impact):**
1. hesreallyhim/awesome-claude-code (24.7k stars, exact target audience)
2. ComposioHQ/awesome-claude-skills (37k stars, largest audience)
3. VoltAgent/awesome-claude-code-subagents (11.1k stars, subagent pattern)

**Tier 2 — Submit next (good fit):**
4. travisvn/awesome-claude-skills (7.5k stars)
5. rohitg00/awesome-claude-code-toolkit (541 stars, very targeted)
6. BehiSecc/awesome-claude-skills (6.2k stars)
7. e2b-dev/awesome-ai-agents (26k stars, broader audience)

**Tier 3 — Submit when time allows:**
8-12. Remaining lists (smaller or less targeted audiences)
