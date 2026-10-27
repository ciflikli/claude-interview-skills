# interview-skills

Claude Code skills for time-boxed live coding: interviews, take-home walkthroughs, timed demos. `interview-mode` is the orchestrator. It starts a countdown, then paces the build with the other skills.

| Plugin | What it does | Used by |
|---|---|---|
| `interview-mode` | Asks build/discussion minutes and scoping questions, starts the timer (status line + per-prompt hook), paces work by the clock | you (`/interview-mode:interview-mode`, "stop interview" ends it) |
| `minimal` | Short, action-first replies; no recaps; commits after every green slice | interview-mode |
| `edd` | Expectation-Driven Development: 1-3 runnable expectations per slice in `EXPECT.md`, verify, atomic commit | interview-mode, plan-split |
| `plan-split` | Splits a brief into parallel workstreams: contract first, exclusive file ownership, worktree + isolated runtime per agent | interview-mode |
| `failure-review` | Reviews a diff for production failure modes (re-runs, crashes, duplicates, bad input, locking, PII); max 3 verified findings | interview-mode, plan-split |
| `coding-practices` | Checklists for Python, databases/pipelines and LLM/agent code | edd, plan-split, failure-review |

Every skill works alone. A skill whose sibling is missing skips that step, and interview-mode tells you which plugins to install.

## Install

```
/plugin marketplace add ciflikli/claude-interview-skills
/plugin install interview-mode@interview-skills
/plugin install minimal@interview-skills
/plugin install edd@interview-skills
/plugin install plan-split@interview-skills
/plugin install failure-review@interview-skills
/plugin install coding-practices@interview-skills
```

Or from a shell:

```bash
claude plugin marketplace add ciflikli/claude-interview-skills
for p in interview-mode minimal edd plan-split failure-review coding-practices; do claude plugin install "$p@interview-skills"; done
```

Requirements: `git`, `jq`. Optional: the [Codex plugin](https://github.com/openai/codex-plugin-cc) (`/codex:setup`) for the background adversarial reviews in plan-split, failure-review and edd. Without it those steps are skipped. If the Codex plugin lives somewhere unusual, set `CODEX_COMPANION_DIR`.

## Optional: countdown in the status line

Plugins can't set the status line, so add this to `~/.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash -c 'f=$(ls -d ~/.claude/plugins/cache/interview-skills/interview-mode/*/ | sort -V | tail -1); exec \"${f}skills/interview-mode/scripts/interview-timer.sh\" status'",
  "refreshInterval": 10
}
```

Without it, the countdown still reaches Claude on every prompt, and `interview-mode` prints a `watch` command for a live countdown in a second terminal.

## Usage

1. `/interview-mode:interview-mode` and answer the time and scoping questions.
2. Paste the brief. Claude plans (plan-split), builds in EDD slices, commits each green slice.
3. Orange (≤37.5% build time left): finish the current slice. Red (<12.5%): freeze, demo, list cuts.
4. Discussion phase: no code changes unless asked; `failure-review` when asked to critique the code.
5. "stop interview".

State lives in `<project>/.claude/` (`interview-timer`, `session-base`, failed patches) and is git-excluded automatically.
