---
name: failure-review
description: >-
  Fast review of a diff for the ways it breaks in production: re-runs, partial failure and crashes, duplicates, bad input, flaky dependencies, concurrency and locking, ordering, resource limits, secrets/PII. Reports at most 3 verified, high-confidence findings with file:line, failure scenario and fix, plus an optional Codex second pass. Use when the user says "failure-review", "review this", or before demoing or handing over code.
---

# failure-review

Find the ways this code breaks in production. Skip style. Follow the minimal skill's output rules if active.

## 1. Get the whole diff (committed work included)
Base, in order of preference: a base the user names, then `.claude/session-base` (written by interview-mode), then `git merge-base HEAD <default branch>`. If none exists, ask: `Review since which commit? (default HEAD~5)`.
- `git diff <base>..HEAD` + `git diff HEAD` (uncommitted) + untracked files from `git status --porcelain`.
- Not a git repo: ask which files changed.
- Read the changed files whole. Also read any unchanged file the diff depends on (data access layer, client wrapper, config).

## 2. Check every boundary the diff touches
| Failure | Question to answer from the code |
|---|---|
| Re-run | Does running it twice change nothing (stable keys, upserts, dedupe, idempotency keys)? |
| Partial failure / crash | If it dies halfway, does a rerun finish without duplicates or stranded work? Short transactions? Leases that expire? |
| Duplicate delivery | At-least-once anywhere? Is the receiving side idempotent? Can a stale worker overwrite newer state? |
| Bad input | Does one bad record crash the batch or retry forever? Is it quarantined with a reason? |
| Flaky dependency | Timeouts set? Retry with backoff + jitter, Retry-After honoured? Auth failures abort instead of being retried or dead-lettered one by one? |
| Concurrency / locking | Any transaction or lock held across a network call? Races on read-then-write? Lock/statement timeouts set? |
| Ordering / incremental | Can an older update overwrite a newer one? Does a checkpoint/watermark advance before the work it covers succeeds? |
| Resource limits | Unbounded memory (loading everything), unbounded concurrency, connection leaks, missing pagination? |
| Secrets / PII | Credentials only from env/secret store? Payloads, tokens or personal data in logs or error messages? |

Then skim the diff against the coding-practices skill's lists (load that skill; `python.md`, `db.md`, `agents.md` sit in its base directory, use their absolute paths), if available. Keep only violations that cause a bug or failure mode.

## 3. Score and filter
For each candidate: confidence (high/med/low) × impact (high/med/low). **Report only high-confidence and high-impact, at most 3.** Verify each one by reading the exact lines (or running a quick check). If it can't be verified, drop it.

## 4. Output
```
1. path/file.py:88 — <what breaks, concrete scenario>. Fix: <concrete change>.
2. ...
Known gaps (by design, say out loud): <1-2 deliberate trade-offs, from project notes if they list any>
```
If nothing survives: `No high-confidence failure modes found.` plus the known gaps line.
Don't fix anything unless the user says so. If they do: fix, rerun the tests, commit the fix on its own (`fix: <failure mode>`), report one line.

## 5. Codex second pass (significant or complex diffs only; needs the Codex plugin)
Trigger: the diff is over ~150 lines, or it touches concurrency, locking, transactions, retries, auth, or a state machine. Skip for small or cosmetic diffs, and in the last 5 minutes of a timed build.
- Run `"<this skill's base directory>/scripts/codex-review.sh" <base> "Production failure modes: re-runs, crashes mid-operation, duplicate delivery, bad input, flaky dependencies, locks held across network calls, ordering, resource limits, secrets in logs. At most 3 findings as file:line, failure scenario, fix."` with Bash `run_in_background`. It's Codex's read-only adversarial review of everything since `<base>`.
- When it returns: verify each finding against the code yourself. Report only the ones that hold up, marked `(codex)`. Drop duplicates of your own findings.
