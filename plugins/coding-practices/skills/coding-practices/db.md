# Databases and data pipelines

## Correctness
- Idempotency: stable business keys, upserts, safe to re-run
- Change detection: content hash / version gate, so no-op writes don't happen
- Ordering: version or `updated_at` guard; an older write never overwrites a newer one
- Constraints in the database (PK, unique, FK, check), not only in code
- Explicit conflict rule (source wins / last write wins) and why

## Data quality (GE/dbt-style, three layers)
- Row: pydantic model per input row (types, required, categories, ranges, formats) -> bad rows quarantined with reason
- Batch: one lazy aggregate pass before any write (row count, duplicate keys, null rate, unknown categories, out-of-range share, required columns present)
- Severity: errors mean "export broken/incomplete" and block destructive steps (deletes, watermark advance); warnings go into the run summary
- Volume and completeness: compare row count to the previous run or a source manifest/count; a valid file is not proof it's complete
- Database: NOT NULL, CHECK, UNIQUE, FK as the last line; post-load assert queries that must return 0 rows
- One test per error rule (failing file -> expected error -> destructive step skipped)

## Failure modes
- Enumerate them: crash mid-write, duplicate delivery, partial batch, dependency down, bad input
- Graceful failures: one bad record never sinks the batch
- Quarantine / dead lettering with a reason; bounded retries, then stop
- Leases with expiry plus heartbeats, so nothing is stranded in-flight
- At-least-once delivery + idempotent effects = effectively once
- Checkpoints / watermarks advance only after the work they cover succeeds

## Concurrency
- Parallelism by disjoint partitions (hash of key) or `FOR UPDATE SKIP LOCKED`
- No worker holds a lock or transaction across a network call
- Short transactions; chunked commits
- Non-blocking locks (`try_lock`, `SKIP LOCKED`) or fail-fast `lock_timeout`
- Statement and idle-in-transaction timeouts as guardrails
- Consistent lock order to avoid deadlocks

## Incremental and OOM protection
- Incremental by default: watermark / `updated_at` / CDC, plus an overlap window; full reloads only on demand
- Stream results: server-side cursors / `fetchmany`, COPY streaming; never `fetchall` on unbounded queries
- Bounded batches: `LIMIT` + keyset loops for backfills and updates; no single giant transaction
- Memory guardrails: `work_mem` awareness, `statement_timeout`; DuckDB `memory_limit` + `temp_directory` to spill
- Polars/DuckDB for file-side processing before loading; push filters down to the source

## Throughput
- Batch / set-based writes (COPY, bulk upsert), not row by row
- Backpressure: bounded queues, bounded worker pools, rate limits
- Minimal, purposeful indexes; partial indexes for hot subsets (e.g. pending rows)
- Connection pooling; one connection per worker
- Keyset pagination, not offset

## Operations
- Additive, non-blocking migrations (`CREATE INDEX CONCURRENTLY`, nullable columns)
- Observability: queue depth, oldest-pending age, dead-letter count, run summaries
- PII: retention and access control for raw/quarantined data
