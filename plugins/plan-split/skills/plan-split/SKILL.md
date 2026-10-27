---
name: plan-split
description: >-
  Split a feature or brief into parallel workstreams that several agents (Claude subagents or Codex) can build at once without blocking each other. Contract first, exclusive file ownership, one git worktree and isolated runtime per agent, atomic commits, merge in dependency order, then a Codex second pass. Use when the user says "plan-split", hands over a brief or spec, or asks how to split or parallelise the work.
---

# plan-split

Goal: a plan the user can read in 30 seconds, built by 2-3 agents in parallel with zero merge conflicts and no agent waiting on another. Follow the minimal skill's output rules if active.

## Inputs (ask only for what's missing, one question)
- The brief/spec, plus real samples of the inputs and outputs (data rows, API request/response, UI mock)
- Constraints: existing code/schema to respect, what matters most if time runs out

## Roles: Claude subagents build, Codex reviews
- **Builders = Claude subagents.** They run in the same harness, read the same skills (edd, coding-practices), report straight back, and can be continued with SendMessage. Codex builders report one way through job polling, don't load these skills, and bring different conventions to the merge.
- **Reviewer = Codex, read-only.** A different model has different blind spots, which is the point of an adversarial review. Read-only means it can't break file ownership, and it runs in the background while building continues.
- Exception: Codex builds a slice only if Claude failed it twice *and* the slice is self-contained. Never under a clock.

## Six rules for parallel workstreams that don't block each other
1. **Contract before code.** Agents code against a frozen interface, never against each other's work in progress. The contract is the shared types/models + sample fixtures (orchestrator-owned), plus one stub file per component holding its function or endpoint signatures (`raise NotImplementedError`). Each stub file is owned by the workstream that implements it. You write all of it serially and commit it before any agent starts.
2. **Exclusive file ownership.** Every file has exactly one owner. Shared files belong to the orchestrator (you): the contract, test config/fixtures, build files (Makefile, package manifests, lockfiles), migrations, and `EXPECT.md`/`PLAN.md`. An agent that needs one of them changed stops and reports it; it doesn't edit.
3. **Isolate the runtime, not just the files.** One git worktree + branch per agent (`ws/S1`...). Then check everything the code touches at runtime that isn't a file in the repo:
   - **Databases:** give each workstream its own database (or container), created and migrated *before* dispatch. A separate schema isn't enough when the code uses database-wide state such as advisory locks, sequences or LISTEN channels.
   - **Ports and services:** each workstream gets an explicit launch command with its own port, plus the matching base URL in its env (`API_BASE_URL=http://localhost:800<n>`). Check for hardcoded ports in build files and config defaults.
   - **Env and deps:** copy gitignored files (`.env`) into each worktree and override the per-workstream values. Install deps per worktree (venv/node_modules aren't shared).
   - **Other shared state:** temp dirs, caches, lock files, queues, global names. Namespace them by workstream.
4. **Fakes instead of waiting.** A workstream that depends on another uses a fake (mock server, in-memory stub, fixture data), not the real thing. Only the final integration slice needs everything real.
5. **Atomic commits on the branch.** One commit per green expectation group, and only the workstream's own files (see edd step 6). That keeps merges and reverts surgical.
6. **Integrate in dependency order.** Merge one branch, run the full test suite + the expectations of slices merged so far, then merge the next. All of EXPECT.md runs only after the final merge. A merge conflict means rule 2 was broken: fix ownership, don't hand-merge.

Sizing: parallelise only workstreams with more than ~5 minutes of work. Spawning an agent costs ~2 minutes. Under a 30-60 minute clock, 2-3 agents at most.

## Steps
1. **Map to the repo.** Read the project's CLAUDE.md/README and the existing types/models. Find the pattern each component should copy. Note shared runtime state (rule 3).
2. **Contract (serial, you).** Update the shared types, add stubs for new functions/endpoints, run the tests, commit: `contract: <what changed>`.
3. **Write `PLAN.md`** (at most 5 rows):
   ```
   # Plan (contract: <commit sha>)
   | # | Workstream | Owns files | Fake for | Runtime (db/port) | Branch | Expectations (edd) |
   | S1 | <component> | <files> | — | db ws_s1, :8001 | ws/S1 | `<cmd>` -> <result> |
   | S2 | <component> | <files> | <fake> | db ws_s2, :8002 | ws/S2 | `<cmd>` -> <result> |
   | S3 | integration (you) | <files> | — | main | main | `<end-to-end cmd>` -> <result> |
   Orchestrator owns: <contract files>, <test config>, <build files>, <migrations>, EXPECT.md, PLAN.md
   Cut (describe, don't build): <items>
   ```
   Check before showing: no file appears in two rows, and every row has its own runtime. Copy the expectations into `EXPECT.md`. Commit `plan: <n> workstreams`.
4. **Codex plan review (background, needs the Codex plugin; skip if absent).** Run `"<this skill's base directory>/scripts/codex-review.sh" <contract-sha>~1 "Challenge this contract and workstream split: hidden coupling between workstreams, shared runtime state, missing failure paths, wrong ownership."` with Bash `run_in_background`. Don't wait for it. Apply findings that hold up to the contract before the agents get deep into it.
5. **Provision** each workstream (rule 3): `git worktree add ../<repo>-S<n> -b ws/S<n> <contract-sha>`, copy `.env` in with its overrides, install deps, create and migrate its database.
6. **Ask one question:** `Run S1-S2 in parallel with agents? (default yes)`

## Dispatch
- One Agent call per parallel workstream, all in the same message, each told to work only in its provisioned worktree path (don't use `isolation: "worktree"`; it would create a fresh, unprovisioned worktree).
- Each prompt contains: the worktree path, the PLAN row, the contract commit sha, "edit ONLY these files; if a shared file must change, stop and report", its runtime settings (db URL, port, env), the slice's expectations, and "follow existing repo patterns and <absolute paths of the coding-practices lists that apply: python.md, db.md, agents.md from that skill's base directory; omit if that skill isn't installed>, smallest diff, run the expectations, one atomic commit per green expectation group on your branch, don't edit EXPECT.md; report pass/fail per expectation and commit shas in 3 lines".
- While they run, build the integration slice yourself against the contract and fakes. Don't idle.

## Integrate
1. Merge branches in dependency order (`git merge --no-ff ws/Sn`). After each one: full tests + expectations of the slices merged so far. Record the results in `EXPECT.md`.
2. Red after a merge: revert it (`git revert -m 1 <merge-sha>`), fix on the branch, then **revert the revert** (`git revert <revert-sha>`) before merging the branch again. Otherwise git treats the original commits as already merged and drops them.
3. If an agent touched a file it doesn't own, drop that file's change from the merge and redo it yourself.
4. Once the final merge is green, run all of EXPECT.md, then remove the worktrees (`git worktree remove ../<repo>-S<n>`).
5. **Codex second pass**: run the failure-review skill (its step 5 sends the merged diff to Codex). If it isn't installed, run `"<this skill's base directory>/scripts/codex-review.sh" <contract-sha> "Production failure modes in the merged workstreams"` in the background instead.
