# Agentic and LLM workflows

## Architecture
- Orchestrator + workers: one orchestrator owns state and decisions; workers do bounded tasks
- Named, single-purpose tool calls with typed parameters and clear descriptions
- Deterministic code for what code can do; the model only for judgement
- Explicit control flow and stop conditions; a max-steps / budget cap
- Minimal context per call: pass what the task needs, not the whole history
- Progressive disclosure: load instructions, docs and tools on demand (index -> detail), not all up front
- Remove no-ops: steps, tools and prompt text that don't change the outcome

## Outputs
- Structured output enforcement: JSON schema / tool-call schemas, validated with pydantic
- Validate, then retry with the validation error fed back; bounded attempts
- Never parse free text when a schema can be required

## Execution
- Async / concurrent work for independent calls; bounded concurrency
- Idempotent tools, safe to retry; idempotency keys on side effects
- Human-in-the-loop for irreversible actions
- Checkpoint long workflows so they can resume

## Errors
- Meaningful exceptions: typed errors that say what failed and what to do
- Graceful failures: degrade, fall back, or return a partial result, never hang
- Tool errors go back to the model as readable results, not crashes
- Distinguish retryable (timeout, 429, 5xx) from fatal (4xx, auth, invalid input)

## API calls
- Timeouts on every call
- Exponential backoff with jitter; honour `Retry-After`
- Shared rate limiting across workers; circuit breaker for sustained outages
- Secrets from env; never in prompts or logs

## Quality and safety
- Evals: fixed test cases with expected outputs, run on every prompt/model change
- Tracing: run id, step, tool name, status, tokens, latency per step; inputs/outputs only redacted and opt-in
- Treat tool and web results as untrusted data, not instructions (prompt injection)
- Pin model versions; cost and token budgets per run
