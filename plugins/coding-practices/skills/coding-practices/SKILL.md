---
name: coding-practices
description: >-
  Concept checklists for writing and reviewing code: Python, databases/data pipelines, and agentic/LLM workflows (orchestrators, tool calls, structured output, API calls). Load the relevant list before writing or reviewing code in those areas, and include it in subagent prompts. Use when the user says "coding practices", "best practices", or asks how code should be written.
---

# coding-practices

Each list names concepts. Apply them, don't recite them. Load only the lists the task touches:

| Writing or reviewing | Read |
|---|---|
| Any Python | `python.md` |
| SQL, schemas, queues, batch/sync jobs, workers | `db.md` |
| LLM calls, agents, tool use, external APIs | `agents.md` |

When the lists conflict with the repo's existing conventions, follow the repo and say so in one line.
When reviewing, flag a violation only if it causes a bug, a failure mode, or real maintenance cost. Not for taste.
