# Failure analysis

## 1. Incomplete retrieval

Top-5 full-evidence rates are below 50% on all three splits. Missing operands and table rows are therefore a normal condition, not an edge case.

## 2. Observer over-triggering

The semantic residual detector has high recall and low specificity. It is good at avoiding silent misses but expensive because it routes many cases into repair.

## 3. Structured-output brittleness

Both observer and answer stages experienced JSON contract failures. Recovery showed that many were serialization defects rather than semantic failures. The lesson is to use structured output only where the state machine actually needs structure.

## 4. Diminishing healing returns

Late-stage autonomous retrieval produced only 29 newly closed development cases. On validation, the expensive healed path recovered one case out of 273 routed cases. The marginal value of repeated LLM-mediated introspection is therefore poor in the measured execution regime.

## 5. Runtime

Stage 1 averaged 25.45 s/case; Stage 2 averaged 36.29 s/case; the terminal resolver averaged 3.55 s/case. The cost is dominated by autoregressive model calls, not local retrieval.

![Runtime comparison](images/figure_34.png)

## 6. Answer quality

Final EM 0.2660 and F1 0.5546 leave substantial room for improvement. Complete terminal coverage should not be confused with verified correctness. The 272 terminal best-effort answers are explicitly labeled.

## 7. v0.2 repair priorities

1. Deterministic retrieval fusion.
2. Deterministic arithmetic and unit verification.
3. One normal model solve.
4. One healing solve only after deterministic failure.
5. Hard call and latency budgets.
6. Preserve the same transaction invariants.
