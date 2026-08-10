# Architecture

## System invariant before components

The architecture is easiest to understand from the invariant: **a candidate retrieval state is not active merely because it was retrieved.** It becomes active only after verification and strict-improvement commit. This divides the system into a durable side and a speculative side.

![Transaction boundary](images/figure_03.png)

## Durable side

The durable state contains question identity, active evidence, frozen requirements, support statuses, residual, seen evidence signatures, action history and terminal status. Checkpoints are flushed and read back. A restart reconstructs this state and skips already completed question UIDs.

## Speculative side

Repair operators build candidate evidence states. v0.1 includes requirement-targeted retrieval, document-local retrieval, lexical search, semantic rewrite, evidence expansion and specialist solving. Candidates are re-audited against the frozen requirements. A candidate is either committed atomically or discarded.

## Controller

The controller maps the operational state to an action order. Missing requirements and uncertain requirements can take different routes. After a commit, routing restarts from the new state. After a rollback, the next bounded operator is tried. Exact repeated evidence signatures are cycles and are rejected.

![Operational state machine](images/figure_02.png)

## Answer subsystem

Answer generation is separated from retrieval closure. A candidate answer can pass, require repair, be judged insufficient, stagnate, cycle or fail technically. Contract failures are recovered separately from semantic failures.

## Validation subsystem

The validation split is document-disjoint. Operational code sees no gold answer. Predictions are frozen durably before the gold map is read for scoring.

![Gold-label isolation](images/figure_41.png)

## v0.2 architecture

The transaction semantics remain, but the execution path compresses to deterministic retrieval fusion, one model solve, deterministic verification, one evidence expansion plus one additional solve if necessary, then commit or escalation.

![v0.2 target](images/figure_48.png)
