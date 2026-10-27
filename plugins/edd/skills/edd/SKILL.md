---
name: edd
description: >-
  Expectation-Driven Development, a lightweight TDD for AI-built code. Before writing each slice, state 1-3 concrete, runnable expectations (command + expected observable result), then build, run every expectation, record pass/fail in EXPECT.md, and commit atomically when green. Use when building features under time pressure or when the user says "edd", "expectations first", or "what should this do".
---

# edd: Expectation-Driven Development

No expectation, no code. An expectation is a runnable check with a concrete expected result, agreed before the code exists. It works like a test, but can be a shell command, a curl, an SQL count, a CLI run, or a unit test.

## Loop (per slice)
1. **Expect.** Append to `EXPECT.md` at repo root (create if missing):
   ```
   ## S1 <slice name>
   - [ ] E1.1 `<exact command>` -> <observable result: output line, count, status code, file/row state>
   - [ ] E1.2 run it again -> no duplicate effects
   - [ ] E1.3 (failure) <bad input / dependency down> -> <handled how: error message, quarantined, retried>
   ```
   Rules: 1-3 per slice. At least one failure-path expectation for anything that can fail. Each has an exact command and an observable result. "Works correctly" is not an expectation.
2. **Show.** Print the expectations in the chat (≤3 lines). Don't wait for approval. The user objects if wrong.
3. **Build.** Smallest diff that can meet them, following the coding-practices skill's lists (load that skill; `python.md`, `db.md`, `agents.md` sit in its base directory, use their absolute paths), if available.
4. **Verify.** Run every expectation in the slice. Tick `[x]`, or mark `[✗]` and append the actual result: `[✗] E1.2 -> got "3 updated"`.
5. **Fix or cut.** Fix a ✗ and re-run all expectations in the slice. **After 2 failed fix attempts, stop guessing:** send the failing expectation, the actual output and the relevant files to the `codex:codex-rescue` agent (Codex plugin; skip if not installed) in the background ("diagnose only, do not edit"). Save the failing diff for it (`git diff > .claude/failed-S<n>.patch`), restore the last green commit (`git restore --staged --worktree <slice files>`, delete new files), then move on to the next slice. If Codex's fix holds up, re-apply the patch plus the fix and re-run. If it isn't fixable in budget, leave it `[✗]` with `CUT: <one-line reason>`.
6. **Commit (atomic).** One commit per green expectation group, and only when green. Stage only the slice's files (`git add <files>`, never `-A`). Message: `S1: <behaviour> (E1.1-E1.3 ✓)`. Never commit red. Never mix two slices, or a refactor, into one commit.
7. **Report** one line: `S1: 3/3 ✓ a1b2c3d` or `S1: 2/3 ✓, E1.3 cut (reason)`.

## In parallel workstreams (plan-split skill)
`EXPECT.md` belongs to the orchestrator. Agents don't edit it. They run their slice's expectations and return results + commit shas, and the orchestrator records them.

## Promote to tests
If an expectation guards a property someone could break later (idempotency, dedupe, retry, auth), and the test takes under 2 minutes to write, make it a real test. Otherwise a shell check is fine.

## Slicing
Vertical slices: each goes end to end and can be demoed. Order by "what would I show if time ended now". Re-run earlier slices' expectations when a change touches shared code.

## Why it reads well when someone is watching
`EXPECT.md` + the git log show intent before code, proof after, and deliberate cuts. Point at them when explaining the work.
