# Self-Healing RAG

## Transactional retrieval repair, verification, rollback, and autonomous recovery

![Self-Healing RAG control loop](images/figure_01.png)

This repository is the complete **v0.1 proof of concept for Self-Healing RAG**. It is not a wrapper around ordinary retrieval with a retry button. It treats retrieval failure as a machine state that can be observed, repaired, verified, committed, rolled back, cycled, checkpointed, and escalated without a human choosing the next action.

**The central claim is explicit:** to the best of the prior-art search documented in this repository, this is the first RAG implementation we have identified whose healing mechanism is formulated as a **transactional retrieval-state controller** with all of the following simultaneously:

- a finite requirement state for each question;
- a discrete residual measuring unresolved evidence;
- explicit repair actions;
- protected already-supported evidence;
- strict residual-improvement commit;
- rollback when a proposal fails verification;
- durable transaction and checkpoint state;
- cycle detection;
- bounded autonomous escalation;
- no human routing gate;
- gold labels isolated from the operational loop.

That is the novelty boundary. Self-RAG, FLARE, CRAG, Self-Correcting RAG, Reflective RAG and related systems are important predecessors in adaptive or corrective retrieval. This repository does not pretend otherwise. The difference is that healing here is an explicit **state-transition and transaction problem** rather than a loose sequence of prompts.

## What is actually in the system

The development lineage is preserved in `EXECUTED_PIPELINE.md`. The working controller evolved through requirement observation, targeted retrieval, document-local repair, transactional verification, answer generation, answer-contract recovery, autonomous escalation, practical bounded validation and a final low-cost terminal resolver. Nothing from that lineage is deleted from this repository.

The operational abstraction is

$$
q \longrightarrow s_0 \xrightarrow{a_0} s_1 \xrightarrow{a_1} \cdots \xrightarrow{a_T} s_T,
$$

where a state contains the active evidence, frozen answer requirements, their support status, residual, action history and terminal status. A proposed transition is committed only when it strictly reduces the residual without destroying previously supported requirements.

The residual used throughout the controller is

$$
\rho(s)=\sum_{i=1}^{m} c(z_i),\qquad
c(\text{supported})=0,\quad
c(\text{uncertain})=1,\quad
c(\text{missing})=2.
$$

The commit rule is

$$
\text{commit}(s\to s') \iff
\rho(s')<\rho(s)
\quad\land\quad
S(s)\subseteq S(s'),
$$

where $S(s)$ is the set of requirement identities already supported in state $s$. A failed candidate is rolled back; it never replaces the durable active state.

![Transaction boundary](images/figure_03.png)

## Frozen v0.1 facts

The strict corpus contains **277 documents and 1,599 questions**. The document-disjoint question split contains **963 development, 312 validation and 324 test questions**. The searchable Chroma store contains **3,838 active paragraph/table-row evidence records**, embedded with `sentence-transformers/all-MiniLM-L6-v2`. The local reasoning model is **Qwen2.5-7B-Instruct in 4-bit NF4** on an **NVIDIA RTX 4060 Laptop GPU with 8 GB VRAM**.

Initial vector retrieval is deliberately exposed rather than hidden. At top-5, requirement recall was 45.80% on development, 46.37% on validation and 42.20% on test. Full-evidence rates at top-5 were 48.49%, 48.40% and 46.60% respectively. At top-50, requirement recall increased to 72.46%, 70.04% and 71.38%. The incomplete top-5 state is therefore not a contrived failure condition; it is the normal operating condition the controller must confront.

![Initial top-5 retrieval](images/figure_17.png)

The full development controller reduced residuals across multiple transactional repair stages. After the final autonomous retrieval controller, the state contained 586 closed cases and 377 retrieval-exhausted cases, with the residual reduced from 1,064 to 915 in that controller alone. The answer stack subsequently committed 682 answers before bounded terminal escalation.

The practical validation lineage then showed the most important engineering lesson of v0.1. A multi-stage LLM-heavy healing path was logically useful but computationally wasteful. On the 312-question validation split, the practical fast path answered 39 cases, the healed path recovered only one additional case, and a deliberately cheap terminal resolver handled the remaining 272 cases in **15.82 minutes**, approximately **3.55 seconds per case**.

The final POC produced **312/312 terminal answers**, normalized exact match **0.2660**, mean token F1 **0.5546**, and accumulated **857 Qwen calls**, or **2.747 calls per validation question** across the complete v0.1 lineage.

![Final validation routing](images/figure_30.png)

These numbers are not presented as state of the art. They are evidence that the control architecture executes autonomously end-to-end, and they expose exactly where the next system must improve.

## Why the repository is structured this way

There is no PDF, no LaTeX source, no hidden supplementary document and no GitHub workflow directory. The technical argument lives directly in Markdown. The figures render directly in GitHub. The entire executed development lineage is also Markdown. A reader should be able to understand the system without downloading a paper or following a chain of external links.

### Read directly in GitHub

- `SELF_HEALING_RAG.md` — the 50-page, 50-figure technical monograph.
- `MATHEMATICS.md` — formal state, residual, transaction, invariants and termination.
- `ARCHITECTURE.md` — controller components and dataflow.
- `ALGORITHMS.md` — executable logic expressed as algorithms and pseudocode.
- `VALIDATION.md` — frozen development and validation results.
- `FAILURE_ANALYSIS.md` — what failed, why it failed, and what v0.1 teaches.
- `PRIOR_ART.md` — direct comparison with adaptive and corrective RAG predecessors.
- `REPRODUCIBILITY.md` — exact environment, files, splits, and rerun contract.
- `EXECUTED_PIPELINE.md` — the complete executed code-and-output lineage supplied for this release.
- `REFERENCES.md` — complete searchable references with DOI/arXiv identifiers.
- `ROADMAP.md` — v0.2 and production-speed design.
- `FIGURES.md` — catalogue of all 50 figures.

## The engineering lesson

The final resolver was dramatically faster than the earlier introspective loops. That result changes the optimization priority but does **not** invalidate the earlier architecture. The correct next system preserves the transactional semantics while pushing cheap deterministic operations forward and expensive LLM operations backward:

$$
\text{retrieval fusion}
\rightarrow
\text{one solve}
\rightarrow
\text{deterministic verification}
\rightarrow
[\text{one healing solve if needed}]
\rightarrow
\text{commit/escalate}.
$$

![v0.2 target architecture](images/figure_48.png)

The v0.1 repository therefore has two jobs. First, it freezes the complete proof that autonomous transactional healing can be built and executed. Second, it creates a hard baseline against which every later simplification must be measured. A faster implementation is acceptable only if it preserves the invariants: no supported-evidence regression, no silent failed transaction, no human routing, no gold leakage, bounded execution and durable terminal state.

## Status

**v0.1: working proof of concept, frozen.**

The next version is not another architectural rewrite. It is an optimization pass over a preserved working lineage. The target is a real-time or near-real-time system with the same state and transaction semantics, far fewer LLM calls, stronger deterministic answer verification, and materially higher exact-match accuracy.
