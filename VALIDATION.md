# Validation

## Frozen corpus

| Item | Count |
|---|---:|
| Documents | 277 |
| Questions | 1,599 |
| Development questions | 963 |
| Validation questions | 312 |
| Test questions | 324 |
| Total units | 14,542 |
| Searchable Chroma records | 3,838 |

## Initial retrieval

| Split | Top-5 requirement recall | Top-5 any evidence | Top-5 full evidence | Top-50 requirement recall |
|---|---:|---:|---:|---:|
| Development | 45.80% | 51.19% | 48.49% | 72.46% |
| Validation | 46.37% | 52.88% | 48.40% | 70.04% |
| Test | 42.20% | 50.00% | 46.60% | 71.38% |

![Retrieval depth](images/figure_13.png)

## Semantic residual detector

Precision 0.5884, recall 0.9201, specificity 0.2802, accuracy 0.6180, F1 0.7178 in the preserved development snapshot.

![Observer metrics](images/figure_19.png)

## Development repair lineage

| Stage | Key result |
|---|---|
| Loop 1 recovered | 323 commits, 442 rollbacks, residual 2,383 → 1,607 |
| Loop 2 recovered | 233 commits, 345 rollbacks, residual 1,607 → 1,064 |
| Autonomous retrieval controller | 557 closed before, 29 newly closed, residual 1,064 → 915 |
| Answer generation | 431 committed, 532 escalated in recorded run |
| Contract recovery | 622 total committed, 341 remained escalated |
| Escalation resolver | 682 total committed, 281 terminal escalations, zero technical failures |

## Practical validation

Stage 1 processed all 312 questions in 2:26:11 and produced 39 fast-path answers. It routed 273 cases to healing. Stage 2 processed those 273 in 2:53:17 and recovered one additional answer.

The terminal resolver preserved the 40 existing answers, processed the remaining 272 cases in 15.82 minutes and produced final terminal predictions for all 312 questions.

| Final metric | Value |
|---|---:|
| Terminal coverage | 312 / 312 |
| Normalized exact match | 0.2660 |
| Mean token F1 | 0.5546 |
| Terminal resolver exact match | 0.2537 |
| Terminal resolver token F1 | 0.5338 |
| Accumulated Qwen calls | 857 |
| Mean accumulated calls/question | 2.747 |

![Final quality](images/figure_31.png)

## Interpretation

The POC is not an accuracy claim. The validation demonstrates autonomous end-to-end execution and, more importantly, reveals the cost structure. The terminal resolver is roughly an order of magnitude faster per case than the earlier LLM-heavy healing stages. That result drives the v0.2 architecture.
