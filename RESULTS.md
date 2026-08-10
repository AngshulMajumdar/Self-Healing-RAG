# Frozen results ledger

This file is a human-readable replacement for machine JSON result snapshots.

## Corpus

| Field | Value |
|---|---:|
| Documents | 277 |
| Questions | 1,599 |
| Development | 963 |
| Validation | 312 |
| Test | 324 |
| Searchable evidence records | 3,838 |

## Initial retrieval MRR

| Split | MRR within top-50 |
|---|---:|
| Development | 0.3807 |
| Validation | 0.4106 |
| Test | 0.3668 |

## Observer snapshot

| Metric | Value |
|---|---:|
| Precision | 0.5884 |
| Recall | 0.9201 |
| Specificity | 0.2802 |
| Accuracy | 0.6180 |
| F1 | 0.7178 |

## Transactional retrieval lineage

| Stage | Before residual | After residual | Reduction |
|---|---:|---:|---:|
| Loop 1 recovered | 2,383 | 1,607 | 776 |
| Loop 2 recovered | 1,607 | 1,064 | 543 |
| Autonomous controller | 1,064 | 915 | 149 |

## Final validation

| Metric | Value |
|---|---:|
| Validation cases | 312 |
| Fast-path answers | 39 |
| Healed-path answers | 1 |
| Terminal best-effort answers | 272 |
| Terminal coverage | 100.00% |
| Exact match | 0.2660 |
| Mean token F1 | 0.5546 |
| Terminal resolver runtime | 15.82 min |
| Terminal resolver seconds/case | 3.55 |
| Accumulated Qwen calls | 857 |
| Mean accumulated calls/question | 2.747 |
