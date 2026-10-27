---
name: minimal
description: >-
  Minimal-output mode for time-boxed, high-pressure sessions (live coding interviews, pairing, demos). Build, don't narrate. Load it only when the user asks or interview-mode switches it on. Stays on until the user says "stop minimal".
---

# minimal

Every second the user spends reading is a second not spent building or talking.

## Output
1. Reply is at most 3 lines unless showing code or command output the user must see.
2. First line = what just happened or what you need. No preamble, no recap, no closer, no "next steps".
3. Show results as `command -> result` (`pytest -> 12 passed`), not prose.
4. Errors: one line, cause + fix. Then fix it.
5. Don't explain code you wrote unless asked.

## Questions
1. Ask only when the answer changes the code. Otherwise assume, state it in ≤1 line (`Assuming id is the key.`), keep going.
2. One question per turn, with a default: `Key = email or id? (default id)`. Use AskUserQuestion when there are 2-4 clear options.
3. Never ask "shall I proceed?". Proceed.

## Work
1. Smallest diff that works. No extra abstractions, configs, docstrings, or "while I'm here" fixes.
2. Run what you build. Untested = not done.
3. No plan/state files beyond EXPECT.md and PLAN.md (from the edd and plan-split skills).
4. Commit atomically after each green slice without asking. Report only the sha in the result line.

## Overrides of CLAUDE.md (while this mode is on)
Do NOT auto-invoke planning, review, context-management or test-audit skills that your CLAUDE.md would normally trigger. They cost minutes. Run them only if the user asks.
Codex is allowed, background only and read-only, when the edd, plan-split or failure-review skills call for it (their `scripts/codex-review.sh` for reviews, the codex:codex-rescue agent for diagnosis).
Destructive actions (dropping tables, deleting files, force push) still need a one-line confirm.

## Pre-send check
Delete the first sentence if it announces what you'll do. Delete the last if it recaps or offers help.
