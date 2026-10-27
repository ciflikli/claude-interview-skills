# Python

## Shape
- Minimal: smallest code that meets the requirement. No speculative features or layers
- Simplicity over elegance: obvious beats clever
- Modular: small functions with one job; pure core, side effects at the edges
- Maintainable: someone new can change it safely in 5 minutes
- Flat over nested: early returns, guard clauses
- Remove no-ops: dead code, pass-through wrappers, unused params/imports, branches that change nothing
- Progressive disclosure: simple public interface up top, details behind it; read top-down

## Naming and readability
- Intuitive, specific names (`unsent_orders`, not `data2`); names replace comments
- No inline comments. A docstring only when the why isn't obvious
- Type hints on public functions; dataclasses/pydantic for structured data

## Constants and config
- Minimal hardcoded constants: named module-level constants or config
- Config and secrets from env; validated once at startup

## Errors
- Explicit, specific exceptions; never bare `except`
- Fail fast on programmer errors; handle expected failures where they can be acted on
- Custom exception types for domain failures; keep the cause (`raise ... from err`)
- Never swallow errors silently; log once, at the boundary

## Resources
- Context managers for files, connections, locks, transactions
- Timeouts on all I/O

## Validation (pydantic)
- Parse, don't validate: turn untrusted input into a model once at the boundary (CSV row, API response, env); typed objects inside
- One model per boundary: input (raw, lenient), internal (normalised), output (what the API accepts); models module = the contract
- Constraints in the type: `Literal`/`Enum` for categories, `Field(ge=, le=, min_length=, pattern=)`, `date`, `Decimal` for money
- Normalise in `field_validator(mode="before")` (trim, lowercase, `"" -> None`); cross-field rules in `model_validator(mode="after")`
- `extra="ignore"` on inbound API models (new server fields don't break us); `extra="forbid"` on config and internal models
- Collect `ValidationError.errors()` into a reason string and quarantine the record; never crash the batch on one bad row
- Batches: `TypeAdapter(list[Model]).validate_python(...)`; don't log `input` from errors (PII)
- Pydantic for boundaries; plain dataclasses / NamedTuples for hot internal structs

## Data
- Polars first; DuckDB for SQL over files or larger-than-memory work; pandas only if the repo already uses it
- Lazy by default: `scan_*` + LazyFrame, filter and project early, collect once

## Incremental and OOM protection
- Incremental: process only new or changed input (watermark, file ledger, content hash); never reprocess everything by default
- Stream, don't load: generators, chunked reads, `collect(engine="streaming")`, `sink_parquet`
- Bounded batch sizes and bounded queues; memory scales with batch size, not input size
- DuckDB: `SET memory_limit` and `temp_directory` so it spills to disk instead of crashing
- No unbounded accumulation: lists, caches, retries, results

## Quality
- Standard library first; few dependencies
- Run through the project runner (`make` / `uv run`); add deps with `uv add`, never bare `pip`/`python`
- Tests for behaviour and failure paths, not implementation details
- Logging: structured, with ids; no PII or payloads
