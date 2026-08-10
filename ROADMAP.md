# Roadmap

## v0.1 — frozen proof of concept

Completed: explicit state, residual, transactional repair, rollback, checkpoints, cycle detection, autonomous escalation, document-disjoint validation and complete development lineage.

## v0.2 — fast controller

The next version keeps the state semantics and replaces the expensive critical path:

1. Preload document-local embedding matrices.
2. Build lexical indexes once.
3. Fuse global vector, document-local dense, lexical and structural-neighbor evidence.
4. One concise Qwen solve.
5. Deterministic extraction/arithmetic/unit verification.
6. One evidence-expansion transaction only after failure.
7. At most one additional Qwen solve.
8. Commit or explicit escalation.

![Action cost ladder](images/figure_42.png)

## v0.3 — answer quality

Add typed operand extraction, deterministic arithmetic execution, scale normalization, table-header reconstruction and evidence citation checks. Keep the two-call cap unless development evidence justifies a change.

## v0.4 — production hardening

Add source trust, prompt-injection defenses, concurrency-safe transaction storage, service-level latency budgets, telemetry and load testing.

## Non-negotiable compatibility

Later versions remain Self-Healing RAG only if they preserve rollback, durable terminal state, gold isolation, no human routing, bounded execution and non-regression of already-supported requirements.
