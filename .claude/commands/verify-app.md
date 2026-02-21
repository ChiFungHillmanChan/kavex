# /verify-app
# 10-Layer Engineering Verification Pipeline
# You are the QA Lead running a production-grade CI/CD gate.
# Nothing ships until ALL 10 layers pass.

## Arguments: $ARGUMENTS
(If provided, focus verification on that area. Otherwise, verify entire project.)

---

## Layer 1: Build
- Run the project's build command. Auto-detect: `build` script in package.json, `go build ./...`, `cargo build`, `mvn compile`, `gradle build`, `dotnet build`
- If build fails, STOP. Nothing else matters until the project compiles.
- Fix all build errors before proceeding.

## Layer 2: Unit Tests (with coverage)
- Vitest: `vitest run --coverage` (check coverage report)
- Jest: `jest --ci --coverage`
- Pytest: `pytest -v --cov`
- Go: `go test ./... -v -cover`
- Rust: `cargo test`
- Ruby: `bundle exec rspec`
- Java: `mvn test` or `gradle test`
- .NET: `dotnet test`
- Fix ALL failures. Zero tolerance.
- Check coverage: if below 80%, flag it in the report. Write missing tests.

## Layer 3: Integration Tests
- If `test:integration` script exists -> run it
- If API route tests exist -> run them
- If database tests exist -> ensure test DB is used, not production
- If no integration tests exist, note the gap in the report.

## Layer 4: E2E Tests (Playwright CLI)
- Run Playwright via the project's package manager or `npx playwright test`
- Fix ALL failures before proceeding.
- If Playwright is not installed, note it and continue.

## Layer 5: Browser Verification (MCP Chrome)
Use the MCP Chrome browser tool to verify the app visually:
1. Check if dev server is running. If not, start it (`npm run dev` or equivalent), wait for ready.
2. Navigate to the app's main URL (usually `http://localhost:3000`)
3. On each key page, verify:
   - [ ] Page loads without JavaScript console errors
   - [ ] No broken images or missing assets (check for 404s)
   - [ ] Navigation links work (click through main nav)
   - [ ] Forms accept input and buttons are clickable
   - [ ] No layout breakage (overlapping elements, overflow, blank sections)
   - [ ] Responsive: check at mobile viewport (375px) if applicable
4. If dev server was not running and cannot be started, skip and note it.

## Layer 6: Accessibility Check (MCP Chrome)
Using MCP Chrome on the running app:
1. Run this JavaScript on each key page:
   ```javascript
   // Check for basic a11y issues
   const images = document.querySelectorAll('img:not([alt])');
   const buttons = document.querySelectorAll('button:empty');
   const inputs = document.querySelectorAll('input:not([aria-label]):not([id])');
   const contrast = document.querySelectorAll('[style*="color"]');
   ```
2. Check for:
   - [ ] All images have alt text
   - [ ] All form inputs have labels or aria-label
   - [ ] All buttons have text content or aria-label
   - [ ] Page has proper heading hierarchy (h1 -> h2 -> h3)
   - [ ] Interactive elements are keyboard-focusable (tab through page)
   - [ ] No empty links or buttons
3. If `axe-core` is available, run it: `axe.run()` via eval

## Layer 7: Performance Check
If the app has a running dev server:
1. Using MCP Chrome, check page load:
   - Navigate to main page
   - Run `performance.getEntriesByType('navigation')[0]` to get load timing
   - Flag if DOM interactive > 3 seconds
2. Check bundle size (if applicable):
   - If build output exists, check largest files
   - Flag any single JS bundle > 500KB
3. If Lighthouse CLI is available: `lighthouse http://localhost:3000 --output=json --quiet`

## Layer 8: Lint
- Run the project's lint command
- Fix ALL errors (not just warnings)
- Check for debug statements across all languages: `console.log`, `print()`, `fmt.Println` (debug), `dbg!`, `puts` (debug), `System.out.println` (debug), `debugger`

## Layer 9: Type Check
- TypeScript: `tsc --noEmit`
- Python: `mypy .` or `pyright`
- Go: `go vet ./...`
- Rust: `cargo check`
- .NET: `dotnet build` (includes type checking)
- Fix ALL type errors. No type-safety bypasses without justification.

## Layer 10: Security & Code Review
Run `git diff main` (or `git diff origin/main`) and check:
- [ ] No hardcoded secrets, API keys, tokens, or passwords
- [ ] No `.env` files being committed
- [ ] Dependency audit passes (`npm/pnpm/yarn audit`, `pip-audit`, `cargo audit`, `bundle-audit`, `govulncheck`)
- [ ] No debug code left in (`console.log`, `print()`, `debugger`)
- [ ] No `TODO` without an issue reference
- [ ] No files over 300 lines
- [ ] No code duplication introduced
- [ ] Unit tests cover all new/changed code paths
- [ ] E2E tests cover all user-facing changes
- [ ] Error handling is meaningful (no empty catches)
- [ ] No new dependencies without justification

---

## Final Report Format:
```
VERIFICATION REPORT — [date]
============================================
 1. Build:          [PASS/FAIL]
 2. Unit Tests:     [X passed, Y failed] — Coverage: Z%
 3. Integration:    [PASS/FAIL/SKIP — reason]
 4. E2E Tests:      [X passed, Y failed]
 5. Browser Check:  [PASS/issues found/skipped]
 6. Accessibility:  [PASS/X issues found]
 7. Performance:    [PASS/flags] — Load: Xs, Bundle: YKB
 8. Lint:           [clean/X errors]
 9. Types:          [clean/X errors]
10. Security+Review:[PASS/X issues]
============================================
VERDICT: READY TO SHIP / NEEDS FIXES
```

## Rules:
- If ANY layer fails, fix it and re-run that layer.
- Only report when ALL layers pass.
- 3 failed attempts on the same issue -> stop and ask the human.
- Layers 5-7 (browser) require dev server. If unavailable, skip and note.
- Coverage below 80% is a warning, not a blocker — but write the missing tests.
