---
name: interview-mode
description: >-
  Start a time-boxed live coding session (interview, take-home walkthrough, timed demo). Asks build/discussion minutes, starts a visible countdown (status line + per-turn timer injection), switches on the minimal and edd skills, and paces the build by the clock. Orchestrates the plan-split, failure-review and coding-practices skills. Invoke with /interview-mode:interview-mode; "stop interview" ends it.
disable-model-invocation: true
---

# interview-mode

## Start (do this immediately, no preamble)
`TIMER` below means the quoted absolute path `"<this skill's base directory>/scripts/interview-timer.sh"`.

0. Check the sibling skills are available: minimal, edd, plan-split, failure-review, coding-practices (separate plugins in this marketplace). For each missing one, print `/plugin install <name>@interview-skills` once and carry on without it.
1. Look for prep notes in the project (`PREP.md`, `NOTES.md`, `CLAUDE.md`, `README.md`). If they contain a build order or talk track, use them in the steps below. Take the scoping questions from them, or else use these:
   1. What are the inputs and outputs? Which side is the source of truth?
   2. What does "done" look like? What would you want demoed?
   3. Scale and constraints: volume, latency, rate limits, failure tolerance?
   4. Existing code, schema or infra I must respect?
   5. If I can't finish, what matters most?
2. Ask everything interactively with AskUserQuestion (max 4 questions per call, so chain calls), in this order:
   - Build time? Options: 40 (default), 30, 45, 60 min
   - Discussion time? Options: 20 (default), 15, 10, 30 min
   - Then each scoping question, one per question, in order. Give 2-3 likely answers as options (from the prep notes or the project, e.g. for inputs/outputs: `File -> service`, `Service -> DB`, `Compare two sources`) plus a last option `Skip`. Short header per question (e.g. "Inputs").
   Call 1 = the two time questions + the first two scoping questions; later calls take the rest. Start the timer (step 4) right after call 1, so later calls don't eat build time unnoticed.
   Use the answers as the scope: treat them as the brief's assumptions, ignore skipped ones, and echo the answered ones in one line each.
3. If the project has no git repo, run `git init` and make a baseline commit of what's there (atomic commits depend on it).
4. Run `TIMER start <build> <discuss>` and print its one-line output. It also records the base commit for failure-review.
5. Tell the user once: `Live countdown in a 2nd terminal: <TIMER as an absolute path> watch`
6. Load the minimal and edd skills now and follow both from here on. Then wait for the brief.

## During build
Each user turn arrives with an `[interview timer]` line from a hook. Obey it:
- **>37.5% of build left (green):** EDD slices in priority order (prep notes' build order if there is one). The core slice should be demo-able by ~60% of build time.
- **≤37.5% left (orange; 15 min of 40):** finish the current slice only. Don't start a new one.
- **<12.5% left (red, FREEZE; 5 min of 40):** no new features. Make sure the main command runs end to end, then output:
  ```
  Works: <command -> result>, ...
  Cut: <item> — <one-line reason> (EXPECT.md CUT lines + unbuilt slices)
  ```
- When the brief or real data arrives, run the plan-split skill. Reuse existing repo patterns; don't write from scratch.
- Commit atomically after every green slice (edd step 6). The git log is your demo script and your safety net.
- Never let a broken build sit for more than 2 turns. Go back to the last green commit and cut the feature.
- Claude subagents build; Codex never edits. Codex runs only in the background and never blocks the build: (a) adversarial review of the plan (plan-split step 4), (b) read-only diagnosis after 2 failed fix attempts (edd step 5), (c) adversarial review once the main slices are merged (failure-review step 5). No new Codex runs once the timer is red.

## Discussion phase
- No code changes unless asked.
- Answers: lead with 2-3 points, each with a mechanism and where it lives in the code (use the prep notes' talk track if there is one). Offer more only on request.
- When asked to review your own code, run the failure-review skill.

## Stop
On "stop interview": run `TIMER stop`, then drop minimal mode.
