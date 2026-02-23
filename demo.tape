# demo.tape — Kova Full Lifecycle Demo
# Generate the GIF: vhs demo.tape
# Requires: https://github.com/charmbracelet/vhs
#
# Demonstrates: install → activate → implement feature →
#               verification catches bug → self-heal → commit clean code

# Terminal settings
Set Shell "bash"
Set FontSize 16
Set Width 1000
Set Height 650
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms
Set WindowBar Colorful
Set WindowBarSize 40

# ─────────────────────────────────────────────
# Scene 1: Install Kova into a project
# ─────────────────────────────────────────────
Type "# Scene 1: Install Kova into your project"
Enter
Sleep 500ms

Type@80ms "curl -fsSL https://raw.githubusercontent.com/ChiFungHillmanChan/kova/main/remote-install.sh | bash"
Enter
Sleep 1s

# Simulate install output
Output ""
Output "  Kova Installer v1.0"
Output "  ────────────────────────────────────────"
Output "  Detecting project... found package.json"
Output "  Stack: Node.js (auto-detected)"
Output ""
Output "  Installing hooks:"
Output "    ✓ .claude/hooks/block-dangerous.sh"
Output "    ✓ .claude/hooks/protect-files.sh"
Output "    ✓ .claude/hooks/format.sh"
Output "    ✓ .claude/hooks/verify-on-stop.sh"
Output "    ✓ .claude/hooks/kova-commit-gate.sh"
Output "  Installing commands:"
Output "    ✓ .claude/commands/kova/"
Output "  Installing CLAUDE.md protocol..."
Output "    ✓ CLAUDE.md"
Output ""
Output "  ✅ Kova installed. Run: kova activate"
Sleep 2s

# ─────────────────────────────────────────────
# Scene 2: Activate Kova
# ─────────────────────────────────────────────
Type "# Scene 2: Activate hooks"
Enter
Sleep 500ms

Type "kova activate"
Enter
Sleep 1s

Output ""
Output "  ✓ Hooks activated in .claude/settings.json"
Output "  ✓ Status: [KOVA] active"
Sleep 1s

Type "kova status"
Enter
Sleep 1s

Output ""
Output "  ┌─────────────────────────────────┐"
Output "  │  KOVA STATUS                    │"
Output "  ├─────────────────────────────────┤"
Output "  │  Hooks:    ✓ active (5 hooks)   │"
Output "  │  Stack:    Node.js              │"
Output "  │  Commands: 9 installed          │"
Output "  │  Safety:   block-dangerous ✓    │"
Output "  │            protect-files  ✓     │"
Output "  │  Verify:   7-layer gate   ✓     │"
Output "  └─────────────────────────────────┘"
Sleep 2s

# ─────────────────────────────────────────────
# Scene 3: Run Kova loop on a small feature
# ─────────────────────────────────────────────
Type "# Scene 3: Implement a feature with /kova:loop"
Enter
Sleep 500ms

Type@100ms 'claude "/kova:loop examples/prd-todo-app.md"'
Enter
Sleep 2s

Output "═══════════════════════════════════════════════"
Sleep 200ms
Output " KOVA LOOP — Starting"
Sleep 200ms
Output " PRD: examples/prd-todo-app.md (5 items)"
Sleep 200ms
Output "═══════════════════════════════════════════════"
Sleep 1s
Output ""
Output "▶ Item 1/5: Create todo.sh CLI"
Output "  Mode: implement"
Sleep 1s
Output "  ✓ Claude session completed"
Sleep 800ms

# ─────────────────────────────────────────────
# Scene 4: Verification gate CATCHES a bug
# ─────────────────────────────────────────────
Output ""
Output "─── Verification Gate ───"
Sleep 500ms
Output "  [1/7] Build ............... ✓ pass"
Sleep 300ms
Output "  [2/7] Tests ............... ✗ FAIL (2 of 8 failed)"
Sleep 500ms
Output ""
Output "  FAILURES:"
Output "    todo.bats:12  'add + list round-trip' — expected 1 item, got 0"
Output "    todo.bats:28  'done marks completion' — exit code 1, expected 0"
Sleep 1s
Output ""
Output "  ❌ Verification FAILED — entering self-heal"
Sleep 1500ms

# ─────────────────────────────────────────────
# Scene 5: Self-healing — Kova auto-retries
# ─────────────────────────────────────────────
Output ""
Output "─── Self-Heal (attempt 1/3) ───"
Sleep 500ms
Output "  Diagnosis: todo.sh write path incorrect — missing newline"
Output "  Spawning Claude fix session..."
Sleep 1s
Output "  ✓ Claude applied fix to todo.sh:17"
Sleep 800ms

Output ""
Output "─── Verification Gate (retry) ───"
Sleep 500ms
Output "  [1/7] Build ............... ✓ pass"
Sleep 200ms
Output "  [2/7] Tests ............... ✓ 8 passed"
Sleep 200ms
Output "  [3/7] Lint ................ ✓ pass"
Sleep 200ms
Output "  [4/7] Typecheck ........... ✓ pass"
Sleep 200ms
Output "  [5/7] Format .............. ✓ pass"
Sleep 200ms
Output "  [6/7] Security ............ ✓ pass"
Sleep 200ms
Output "  [7/7] Coverage ............ ✓ pass"
Sleep 500ms
Output ""
Output "  ✅ Verification PASSED"
Sleep 1s

# ─────────────────────────────────────────────
# Scene 6: Code review + commit clean code
# ─────────────────────────────────────────────
Output ""
Output "─── Code Review ───"
Sleep 500ms
Output "  Reviewer: Claude (separate session)"
Output "  Verdict: PASS — no issues found"
Sleep 800ms
Output ""
Output "─── Commit ───"
Sleep 500ms
Output "  feat(todo): create todo.sh CLI with add, list, done, clear"
Output "  2 files changed, 48 insertions(+)"
Sleep 800ms
Output ""
Output "═══════════════════════════════════════════════"
Output " KOVA LOOP — Complete (1/5 shipped, continuing...)"
Output "═══════════════════════════════════════════════"
Sleep 3s
