# Prior art and novelty boundary

## The claim

This repository does **not** claim that adaptive retrieval, self-reflection, corrective retrieval or the phrase “self-healing RAG” originated here. Those claims would be indefensible.

The claim is narrower:

> **To the best of the documented prior-art search, this is the first RAG implementation identified that makes healing an explicit transaction system over persistent retrieval state with a finite requirement state, discrete residual, protected support, strict improvement commit/rollback, durable transaction history, cycle detection, and bounded autonomous escalation.**

## Self-RAG

Self-RAG [9] learns reflection tokens that control retrieval, generation and critique. It is a direct predecessor in self-reflective adaptive RAG. Its reflection semantics are model-internal; this system externalizes persistent state and transaction semantics.

## FLARE and active retrieval

FLARE [8] retrieves during generation based on predicted future content and low-confidence tokens. The present system instead triggers repair from unresolved requirement state and evaluates candidate evidence through a transaction rule.

## CRAG

CRAG [10] evaluates retrieval quality and triggers corrective retrieval actions. It is a direct predecessor in corrective RAG. The distinction here is the explicit residual plus commit/rollback over durable state.

## RAGAS, ARES and RAGChecker

These systems [12–14] establish component-level RAG evaluation and diagnosis. The present controller turns diagnosis into a persistent action-and-transaction loop.

## 2026 self-corrective and reflective systems

Self-Correcting RAG [17], Reflective RAG [18], ReflectiveRAG [19], SEMA-RAG [20] and self-triggered retrieval planning [21] make the contemporary landscape highly adaptive. The novelty claim must therefore remain architectural, not rhetorical.

![Prior-art comparison](images/figure_49.png)

## Falsifiability

The claim should be revised if an earlier public implementation is found that combines the full transaction semantics under the same operational meaning. That is a feature, not a weakness: a technical priority claim should have a testable boundary.
