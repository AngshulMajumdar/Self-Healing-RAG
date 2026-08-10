# Self-Healing RAG

## A 50-page / 50-figure technical monograph in Markdown

**Version:** v0.1 proof of concept  
**Scope:** transactional retrieval repair, autonomous recovery, validation and the path to a fast production implementation.

This document is deliberately GitHub-native. Every page is Markdown and every figure renders inline. The complete executed code-and-output lineage is preserved separately in `EXECUTED_PIPELINE.md`. Citations refer to the numbered bibliography in `REFERENCES.md`.

---

## Page 01 — Autonomous control loop

The system described here is called **Self-Healing RAG** because retrieval failure is not treated as a one-shot defect. It is represented as an operational state from which the controller can autonomously move. The controller can identify unresolved requirements, select a repair action, build a candidate evidence state, verify the candidate, commit it when the residual improves, roll it back when it does not, detect cycles, checkpoint progress and terminate with either a closed state or an explicit escalation. The word *healing* therefore refers to a defined state transition, not to a marketing synonym for “retry”.

The priority claim is deliberately technical. Earlier systems already perform adaptive retrieval, self-reflection, corrective retrieval, iterative retrieval, self-evaluation and answer verification [8–14,17–21]. The claim made by this repository is that the present implementation is the first one identified in the documented prior-art search that combines those concerns into an explicit **transaction system over persistent retrieval state**: frozen requirement identities, a discrete residual, protected support, strict improvement commit, rollback, durable transaction logs, cycle detection and bounded autonomous escalation.

That claim is falsifiable. An earlier implementation exhibiting the same architecture would narrow or defeat it. This is preferable to a vague claim of being “more agentic” or “more reliable”. The architecture itself is the object being released.

The design objective is stronger than automatic retry. The system must be able to run without a person examining diagnostic output and deciding which branch to execute. Every branch selection must be derivable from machine state. Diagnostics may be printed for audit, but they are not control inputs.

The controller therefore requires five properties. First, the evidence state must be observable. Second, candidate changes must be reversible. Third, progress must be measurable independently of the candidate action. Fourth, repeated actions must terminate rather than oscillate forever. Fifth, every terminal outcome must be explicit: closed, corpus-insufficient, stagnated, cycled or technically failed.

This design directly borrows the discipline of transaction processing and self-adaptive software [24–25]. The retrieved evidence is treated as durable state. A repair proposal is tentative. Verification occurs before activation. Commit and rollback are explicit decisions. The result is a RAG system whose failure handling is governed by invariants rather than prompt convention.

![Figure 1: Autonomous control loop](images/figure_01.png)

---

## Page 02 — Operational state machine

For a question $q$, define an operational state

$$s=(q,E,R,h,\tau),$$

where $E=(e_1,\ldots,e_k)$ is the active evidence list, $R=(r_1,\ldots,r_m)$ is the frozen requirement vector, $h$ is the set of previously visited evidence signatures, and $\tau$ is the durable transaction history. Each requirement $r_i$ has a stable identity, a textual description, a status and zero or more supporting evidence IDs.

The state is deliberately richer than a prompt. A prompt disappears after generation. The state survives retries, failures and kernel restarts because it is materialized in checkpoint and transaction files. This distinction matters: a self-healing system needs memory of what it has already tried, which evidence it has already protected, and why a previous proposal was rejected.

A state is *closed* when every requirement is supported. It is *open-missing* when at least one required fact is absent. It is *open-uncertain* when no requirement is strictly missing but one or more remain ambiguous or incomplete. These operational labels determine which repair family is tried first.

![Figure 2: Operational state machine](images/figure_02.png)

---

## Page 03 — The retrieval repair is a transaction

A repair attempt can be written as a transaction

$$T=(s,a,p,v,d,s^*),$$

where $s$ is the durable input state, $a$ is the selected action, $p$ is the proposed evidence state, $v$ is the verification result, $d\in\{\text{commit},\text{rollback}\}$ is the decision, and $s^*$ is the durable state after the transaction.

The proposal is never automatically active. It lives outside the durable state until verification completes. This is the critical systems distinction. Many “self-correcting” loops overwrite their context with every retry and rely on the model to recover. Here, a failed proposal is disposable. The last committed state remains authoritative.

Every transaction is serializable to JSONL in the executed implementation, but this GitHub release documents it in Markdown rather than requiring readers to inspect raw machine files. The full executable lineage remains in `EXECUTED_PIPELINE.md`.

![Figure 3: The retrieval repair is a transaction](images/figure_03.png)

---

## Page 04 — Requirement vector

The controller does not attempt to repair an answer string directly. It first decomposes the question into the smallest evidence requirements needed to determine the answer. For a ratio question, for example, the numerator and denominator are distinct requirements. For a percentage change, the old value and the new value are separate requirements. Entity, period, direction and unit constraints are part of the requirement descriptions when they determine which number is admissible.

This decomposition is essential because a five-record retrieval set can look semantically relevant while still omitting one operand. Treating the whole question as a single relevance target hides this defect. Requirement-level state exposes it.

Requirement identities are frozen during a transaction. A candidate verifier may change only the status and supporting evidence IDs. It may not rewrite the problem into an easier one, silently delete a requirement, merge two requirements, or create a new requirement after seeing a proposal. Freezing the requirement vector is what makes residual comparison meaningful.

![Figure 4: Requirement vector](images/figure_04.png)

---

## Page 05 — Residual as a discrete control objective

Each requirement is assigned one of three statuses: **supported**, **uncertain**, or **missing**. The v0.1 implementation maps them to integer costs

$$c(S)=0,\qquad c(U)=1,\qquad c(M)=2.$$

The ordering is intentional. A related but incomplete record is better than complete absence, but it is not equivalent to support. The controller is therefore able to recognize partial progress without pretending that ambiguity is closure.

This cost function is small enough to audit and strong enough to induce a well-founded descent. It also avoids using answer correctness as an internal control signal. During operation the controller does not know the benchmark answer. It knows only the question, active evidence, frozen requirements and verifier judgments. Gold labels remain outside the loop until predictions have been frozen.

The operational residual is the sum of requirement costs,

$$\rho(s)=\sum_{i=1}^{m} c(z_i),$$

where $z_i$ is the status of requirement $i$. The residual is not a probability, confidence score or learned reward. It is an integer count of unresolved evidence severity.

That simplicity gives the controller a precise monotone objective. A candidate state with lower residual is strictly better, provided it has not destroyed previously supported requirements. A candidate with equal residual may have rearranged evidence but has not demonstrated operational improvement. A candidate with higher residual is worse and must be rejected.

Across development, this residual made large repair stages directly measurable. The final recovered Loop 1 reduced residual from 2,383 to 1,607. Loop 2 reduced it from 1,607 to 1,064. The autonomous controller further reduced it from 1,064 to 915. These are state changes, not answer-score changes.

![Figure 5: Residual as a discrete control objective](images/figure_05.png)

---

## Page 06 — Strict-improvement commit rule

The core acceptance condition is

$$\operatorname{commit}(s\rightarrow s')\iff
\rho(s')<\rho(s)
\ \land\
S(s)\subseteq S(s'),$$

where $S(s)$ denotes the set of requirement identities whose status is supported in $s$.

The first clause demands strict residual improvement. The second forbids regression of already-supported requirements. Together they eliminate two common pathologies: accepting a proposal merely because it is different, and replacing one correct piece of evidence with another retrieval set that solves a different part of the question while losing previous support.

The rule is deliberately conservative. It can reject potentially useful lateral moves whose residual remains equal. That conservatism is acceptable in v0.1 because correctness of state evolution is more important than maximizing exploratory breadth. Later versions may permit multi-step transactions with a bounded temporary residual increase, but only if the rollback boundary remains explicit.

![Figure 6: Strict-improvement commit rule](images/figure_06.png)

---

## Page 07 — Protected evidence

When a requirement is already supported by a particular evidence unit, that evidence receives protection during proposal construction. Free top-k slots are filled first. A repair operator cannot casually evict protected evidence merely because another document fragment has a higher similarity score.

This is a direct response to the instability of repeated top-k retrieval. A new query can reorder the candidate list and accidentally discard the only record containing a previously recovered operand. If the controller then re-verifies the whole state, it may oscillate between different partial solutions.

Protection does not make evidence immutable forever. It makes support part of the commit contract. A later transaction may replace a protected item only when the complete candidate state still verifies the same requirement and strictly improves the residual. Thus evidence protection is semantic, not positional.

![Figure 7: Protected evidence](images/figure_07.png)

---

## Page 08 — Bounded repair action set

The development system accumulated several repair operators: requirement-targeted semantic retrieval, document-local retrieval, exhaustive lexical search, rewritten semantic queries, evidence expansion and specialist answer solving. These operators have very different computational costs.

v0.1 initially allowed the language model to participate deeply in observation, rewriting, verification and answer repair. That architecture was useful for exposing states and testing invariants, but validation showed that it is too slow for a practical system. The final terminal resolver demonstrated that a much cheaper path can recover terminal coverage when same-document evidence is assembled deterministically.

The correct conclusion is not to delete the earlier operators. They remain useful experimental actions and preserve the development history. The conclusion is to order actions by cost and expected information gain. Cheap matrix and lexical operations should dominate early repair. LLM calls should occur only after deterministic evidence assembly has been exhausted.

![Figure 8: Bounded repair action set](images/figure_08.png)

---

## Page 09 — Cycle detection

A healing loop can fail by returning to an evidence state it has already visited. The implemented controller stores signatures of active evidence-ID tuples. If a proposal recreates a seen signature, that branch is rejected rather than executed again.

The signature is simple:

$$\sigma(E)=(\operatorname{id}(e_1),\ldots,\operatorname{id}(e_k)).$$

This exact-state test does not detect every semantic cycle, but it prevents the most dangerous operational failure: an unbounded loop that repeatedly swaps or reconstructs the same top-k evidence. The final autonomous escalation resolver reported 220 cycle terminations, demonstrating that cycle handling is not theoretical decoration; it was exercised in the development lineage.

Future systems can strengthen the signature with canonicalized requirement support, retrieval-query hashes or semantic equivalence classes. Exact ID signatures are nevertheless enough to make v0.1 branches bounded and auditable.

![Figure 9: Cycle detection](images/figure_09.png)

---

## Page 10 — Why the controller terminates

Termination follows from three implemented facts. The residual is a non-negative integer. Every committed transition strictly lowers it. The action set is bounded, and exact repeated evidence states are rejected. Therefore an individual controller branch cannot execute an infinite sequence of committed improvements, and it cannot execute an infinite sequence of identical non-improving proposals.

The terminal set contains both success and explicit failure states. Closure is success. Corpus insufficiency, stagnation, cycle and technical failure are explicit escalations. This distinction matters because a reliable system must not hide “could not repair” behind a generated answer.

The POC later adds a terminal best-effort answer stage to ensure every validation case has a prediction for scoring. That stage is outside the strict closure semantics. The repository labels those 272 cases `committed_terminal_best_effort`, preserving the difference between an operationally verified answer and a benchmark prediction produced for complete terminal coverage.

![Figure 10: Why the controller terminates](images/figure_10.png)

---

## Page 11 — Data lineage

The POC uses an exact TAT-DQA/TAT-QA bridge constructed into a strict local corpus. The frozen corpus contains 277 documents, 1,599 questions and 14,542 total units. Of those units, 3,838 paragraph and table-row records are active searchable evidence in Chroma.

The question split is document-disjoint: 963 development questions, 312 validation questions and 324 test questions. Document identity is assigned before question evaluation so that questions from the same source document do not cross the development/validation/test boundary.

This split matters because the controller is allowed to know a question’s source document during document-local repair. If the same source document appeared in both development and validation, a tuned document-level repair policy could leak structural information across the evaluation boundary. The split contract prevents that.

The searchable store is a persistent Chroma collection named `tatdqa_evidence_v1`. It contains 3,838 active evidence records with 384-dimensional embeddings produced by `sentence-transformers/all-MiniLM-L6-v2`. Query and stored embeddings are L2 normalized and searched using cosine distance.

The persistent database is verified against a manifest before use. Record count and embedding dimension are checked. The local migration stage verifies file hashes before extraction, after extraction and again after commit to the project directory. This is another example of the repository’s systems bias: data integrity is treated as part of the experiment rather than as an assumption.

Later validation cells reuse precomputed vector-search rankings where possible. This reduces wasted retrieval work and makes it possible to separate controller cost from initial retrieval cost.

![Figure 11: Data lineage](images/figure_11.png)

---

## Page 12 — Document-disjoint question split

The POC uses an exact TAT-DQA/TAT-QA bridge constructed into a strict local corpus. The frozen corpus contains 277 documents, 1,599 questions and 14,542 total units. Of those units, 3,838 paragraph and table-row records are active searchable evidence in Chroma.

The question split is document-disjoint: 963 development questions, 312 validation questions and 324 test questions. Document identity is assigned before question evaluation so that questions from the same source document do not cross the development/validation/test boundary.

This split matters because the controller is allowed to know a question’s source document during document-local repair. If the same source document appeared in both development and validation, a tuned document-level repair policy could leak structural information across the evaluation boundary. The split contract prevents that.

![Figure 12: Document-disjoint question split](images/figure_12.png)

---

## Page 13 — Requirement recall versus retrieval depth

The baseline vector search evaluates retrieval depth at $k\in\{1,3,5,10,20,50\}$. For each question, requirement-level coverage is evaluated offline using acceptable evidence-unit groups. Those gold groups are used only for evaluation; they are not passed into the operational query.

At top-5, development requirement recall is 45.80%, validation 46.37% and test 42.20%. Any-evidence rates are 51.19%, 52.88% and 50.00%. Full-evidence rates are 48.49%, 48.40% and 46.60%. These figures establish the starting problem: top-5 retrieval is not a reliable complete context.

At top-50, recall rises above 70% on all three splits, but blindly sending 50 records to a generator would increase context cost and noise. Self-healing instead asks whether the current evidence is sufficient and retrieves more selectively when it is not.

![Figure 13: Requirement recall versus retrieval depth](images/figure_13.png)

---

## Page 14 — Any-evidence rate versus retrieval depth

The retrieval curves show diminishing returns. Increasing $k$ from 1 to 5 produces large gains; increasing from 20 to 50 produces smaller gains while context size grows rapidly. This is precisely the regime where a controller is useful.

A static system must choose one global $k$. A healing system can start narrow, then spend retrieval budget selectively on cases whose evidence state remains open. The theoretical benefit is obvious, but v0.1 also exposes the practical trap: if the decision to retrieve more requires several expensive LLM calls, adaptive retrieval can cost more than simply retrieving a larger deterministic pool.

The v0.2 direction therefore keeps adaptive evidence growth but removes LLM-heavy introspection from the critical path. Retrieval depth becomes a cheap action variable; model inference becomes a scarce resource.

![Figure 14: Any-evidence rate versus retrieval depth](images/figure_14.png)

---

## Page 15 — Full-evidence rate versus retrieval depth

The baseline vector search evaluates retrieval depth at $k\in\{1,3,5,10,20,50\}$. For each question, requirement-level coverage is evaluated offline using acceptable evidence-unit groups. Those gold groups are used only for evaluation; they are not passed into the operational query.

At top-5, development requirement recall is 45.80%, validation 46.37% and test 42.20%. Any-evidence rates are 51.19%, 52.88% and 50.00%. Full-evidence rates are 48.49%, 48.40% and 46.60%. These figures establish the starting problem: top-5 retrieval is not a reliable complete context.

At top-50, recall rises above 70% on all three splits, but blindly sending 50 records to a generator would increase context cost and noise. Self-healing instead asks whether the current evidence is sufficient and retrieves more selectively when it is not.

The retrieval curves show diminishing returns. Increasing $k$ from 1 to 5 produces large gains; increasing from 20 to 50 produces smaller gains while context size grows rapidly. This is precisely the regime where a controller is useful.

A static system must choose one global $k$. A healing system can start narrow, then spend retrieval budget selectively on cases whose evidence state remains open. The theoretical benefit is obvious, but v0.1 also exposes the practical trap: if the decision to retrieve more requires several expensive LLM calls, adaptive retrieval can cost more than simply retrieving a larger deterministic pool.

The v0.2 direction therefore keeps adaptive evidence growth but removes LLM-heavy introspection from the critical path. Retrieval depth becomes a cheap action variable; model inference becomes a scarce resource.

![Figure 15: Full-evidence rate versus retrieval depth](images/figure_15.png)

---

## Page 16 — Mean reciprocal rank within top-50

The baseline vector search evaluates retrieval depth at $k\in\{1,3,5,10,20,50\}$. For each question, requirement-level coverage is evaluated offline using acceptable evidence-unit groups. Those gold groups are used only for evaluation; they are not passed into the operational query.

At top-5, development requirement recall is 45.80%, validation 46.37% and test 42.20%. Any-evidence rates are 51.19%, 52.88% and 50.00%. Full-evidence rates are 48.49%, 48.40% and 46.60%. These figures establish the starting problem: top-5 retrieval is not a reliable complete context.

At top-50, recall rises above 70% on all three splits, but blindly sending 50 records to a generator would increase context cost and noise. Self-healing instead asks whether the current evidence is sufficient and retrieves more selectively when it is not.

![Figure 16: Mean reciprocal rank within top-50](images/figure_16.png)

---

## Page 17 — Initial top-5 retrieval is materially incomplete

A conventional RAG pipeline retrieves a fixed number of records and passes them to a generator. When the answer is wrong, at least three failure classes are entangled: the corpus may not contain the fact, the retriever may have missed it, or the generator may have failed to use evidence that was actually present. A single output score cannot distinguish these cases. Consequently, a conventional pipeline has no principled answer to the question “what should happen next?”

The v0.1 corpus makes that problem concrete. At the initial top-5 retrieval depth, requirement recall is only 45.80% on development, 46.37% on validation and 42.20% on test. Full-evidence rates are 48.49%, 48.40% and 46.60%. These are not rare edge cases. Roughly half of the questions enter generation without all evidence requirements represented in the top-5 set. Simply asking a stronger generator to “try harder” does not repair the retrieval state.

Self-healing begins by refusing to collapse all failure into answer error. Retrieval state is first-class. An answer can be withheld, repaired or escalated because the controller has an explicit representation of what remains unresolved.

![Figure 17: Initial top-5 retrieval is materially incomplete](images/figure_17.png)

---

## Page 18 — Semantic residual detector confusion matrix

The semantic observer maps a question and five evidence records to a requirement vector with statuses. The model is Qwen2.5-7B-Instruct loaded locally in 4-bit NF4 quantization. The observer contract forbids answering the question and limits itself to requirement descriptions, support status and evidence rank.

The initial residual detector favored recall over specificity. In one measured development snapshot it achieved precision 0.5884, recall 0.9201, specificity 0.2802, accuracy 0.6180 and F1 0.7178. This is an important characteristic: the observer was aggressive about declaring retrieval necessary. That behavior protects against silent missing evidence but can drive excessive healing calls.

The observer therefore served its architectural purpose—making retrieval insufficiency explicit—but also became a major latency source. The POC demonstrates both facts rather than hiding the trade-off.

![Figure 18: Semantic residual detector confusion matrix](images/figure_18.png)

---

## Page 19 — Semantic residual detector metrics

The semantic observer maps a question and five evidence records to a requirement vector with statuses. The model is Qwen2.5-7B-Instruct loaded locally in 4-bit NF4 quantization. The observer contract forbids answering the question and limits itself to requirement descriptions, support status and evidence rank.

The initial residual detector favored recall over specificity. In one measured development snapshot it achieved precision 0.5884, recall 0.9201, specificity 0.2802, accuracy 0.6180 and F1 0.7178. This is an important characteristic: the observer was aggressive about declaring retrieval necessary. That behavior protects against silent missing evidence but can drive excessive healing calls.

The observer therefore served its architectural purpose—making retrieval insufficiency explicit—but also became a major latency source. The POC demonstrates both facts rather than hiding the trade-off.

![Figure 19: Semantic residual detector metrics](images/figure_19.png)

---

## Page 20 — Observer recovery closed the contract gap

Structured LLM output is itself a failure surface. The observer originally used a strict JSON contract. Eighty-six development cases failed the first durable pass because the model’s output did not satisfy the parser contract, even though the semantic task was often recoverable.

A recovery cell targeted only those failures and eventually produced durable observer states for all 963 development questions with zero conservative fallbacks and zero uncommitted cases in that run. The episode is instructive: a self-healing system must distinguish semantic failure from serialization failure.

Later answer recovery applies the same lesson. Contract-light final-answer parsing is more efficient than repeatedly asking a 7B model to regenerate semantically identical content just because a bracket or field name is wrong. This becomes a direct design rule for v0.2.

![Figure 20: Observer recovery closed the contract gap](images/figure_20.png)

---

## Page 21 — Loop 1 requirement-targeted repair transactions

Loop 1 constructs retrieval proposals targeted at unresolved requirement descriptions. Proposals do not directly modify the observer state. They are separately re-observed against the same frozen requirements, then passed through the strict commit rule.

After verifier-failure recovery, the authoritative Loop 1 state recorded 323 commits and 442 rollbacks. Residual fell from 2,383 to 1,607, a reduction of 776. Closed cases increased to 385. The large rollback count is not wasted evidence of failure; it shows that the controller was genuinely testing candidate retrieval states rather than automatically accepting every additional search result.

This stage establishes the transaction pattern used by later controllers: proposal, independent evaluation, commit only on strict improvement, otherwise rollback.

![Figure 21: Loop 1 requirement-targeted repair transactions](images/figure_21.png)

---

## Page 22 — Loop 1 residual reduction

Loop 1 constructs retrieval proposals targeted at unresolved requirement descriptions. Proposals do not directly modify the observer state. They are separately re-observed against the same frozen requirements, then passed through the strict commit rule.

After verifier-failure recovery, the authoritative Loop 1 state recorded 323 commits and 442 rollbacks. Residual fell from 2,383 to 1,607, a reduction of 776. Closed cases increased to 385. The large rollback count is not wasted evidence of failure; it shows that the controller was genuinely testing candidate retrieval states rather than automatically accepting every additional search result.

This stage establishes the transaction pattern used by later controllers: proposal, independent evaluation, commit only on strict improvement, otherwise rollback.

The first Loop 1 transaction pass contained verifier contract failures. A dedicated recovery step re-evaluated only those failed transactions, leaving already-successful transactions untouched. This incremental repair preserved prior computation and recovered all verification failures in the authoritative state.

This is an example of healing applied to the controller itself. The retrieval state machine can remain conceptually correct while the implementation around it fails due to a brittle output contract. Recovery should therefore target the smallest failed component, not restart the entire pipeline.

The same engineering discipline is used throughout the release: checkpoint completed work, isolate the failed subset, repair that subset, and reconstruct the authoritative state from durable transactions.

![Figure 22: Loop 1 residual reduction](images/figure_22.png)

---

## Page 23 — Loop 2 document-local repair transactions

Loop 2 exploits a fact available in the strict corpus: the source document UID is known. Once a question is associated with a source financial report, repair can search within that document rather than contaminating the state with globally similar records from unrelated companies.

This is particularly important in financial QA. Terms such as “current liabilities”, “research and development”, or “operating expenses” recur across many reports. Global semantic retrieval can return an excellent lexical match from the wrong company. Document-local repair prevents that failure by construction.

After verifier-failure recovery, Loop 2 recorded 233 commits and 345 rollbacks. Residual fell from 1,607 to 1,064, a reduction of 543, and the number of closed cases reached 557. The document boundary therefore produced substantial additional progress without relaxing the commit invariant.

![Figure 23: Loop 2 document-local repair transactions](images/figure_23.png)

---

## Page 24 — Loop 2 residual reduction

Loop 2 exploits a fact available in the strict corpus: the source document UID is known. Once a question is associated with a source financial report, repair can search within that document rather than contaminating the state with globally similar records from unrelated companies.

This is particularly important in financial QA. Terms such as “current liabilities”, “research and development”, or “operating expenses” recur across many reports. Global semantic retrieval can return an excellent lexical match from the wrong company. Document-local repair prevents that failure by construction.

After verifier-failure recovery, Loop 2 recorded 233 commits and 345 rollbacks. Residual fell from 1,607 to 1,064, a reduction of 543, and the number of closed cases reached 557. The document boundary therefore produced substantial additional progress without relaxing the commit invariant.

![Figure 24: Loop 2 residual reduction](images/figure_24.png)

---

## Page 25 — Autonomous retrieval controller

The corrected autonomous controller removes hard-coded case counts and manual diagnostic routing. It begins from the authoritative post-Loop-2 state, chooses actions from operational state, checkpoints every case, detects cycles and marks cases `retrieval_exhausted` when no bounded operator can strictly improve the residual.

On the recorded development run, 557 cases were closed before the controller and 406 were open. The controller newly closed 29, leaving 377 retrieval-exhausted cases. Residual fell from 1,064 to 915. The modest gain compared with earlier loops is informative: by this stage the remaining cases are harder, and repeated model-mediated repair has sharply diminishing returns.

This controller is the clearest proof of the “no human routing” claim. The case does not wait for a person after diagnosis. The policy itself chooses the next action or terminal escalation.

![Figure 25: Autonomous retrieval controller](images/figure_25.png)

---

## Page 26 — Autonomous controller residual reduction

The corrected autonomous controller removes hard-coded case counts and manual diagnostic routing. It begins from the authoritative post-Loop-2 state, chooses actions from operational state, checkpoints every case, detects cycles and marks cases `retrieval_exhausted` when no bounded operator can strictly improve the residual.

On the recorded development run, 557 cases were closed before the controller and 406 were open. The controller newly closed 29, leaving 377 retrieval-exhausted cases. Residual fell from 1,064 to 915. The modest gain compared with earlier loops is informative: by this stage the remaining cases are harder, and repeated model-mediated repair has sharply diminishing returns.

This controller is the clearest proof of the “no human routing” claim. The case does not wait for a person after diagnosis. The policy itself chooses the next action or terminal escalation.

![Figure 26: Autonomous controller residual reduction](images/figure_26.png)

---

## Page 27 — Autonomous answer generation

Once retrieval state is fixed, Cell 23 generates answers for every development case, independently verifies them against committed evidence and attempts semantic repair when verification returns REPAIR. Hidden benchmark answers are never read by the generator, verifier or controller.

In the preserved executed transcript, the answer generator committed 431 verified answers and escalated 532 cases. It also exposed a large generation-contract problem: 106 contract failures in that particular recorded run. Verification contract failures were zero.

The separation between retrieval closure and answer commitment is important. A closed retrieval state does not guarantee a correct generator output. Conversely, a retrieval-exhausted state may still contain enough information for a robust answer solver. The architecture therefore treats answer verification as a distinct state transition rather than assuming retrieval quality and answer quality are identical.

![Figure 27: Autonomous answer generation](images/figure_27.png)

---

## Page 28 — Answer-contract recovery

Cell 24 attacks only answer-generation contract failures. It replaces the brittle multi-field answer object with contract-light final-answer text, then independently verifies the answer against the same evidence. The semantic problem is unchanged; only the serialization burden is removed.

The recorded recovery targeted 440 generation failures in the later full lineage, committed 191 recovered cases, brought the total committed verified answers to 622, and left 341 escalated. It eliminated generation and verification contract failures after recovery.

This stage is one of the strongest engineering lessons in the repository. Structured output is valuable when the structure is necessary for control. It is wasteful when the structure merely gives the parser more ways to reject an otherwise usable answer. v0.2 should keep structured state where state semantics require it and use minimal output contracts everywhere else.

![Figure 28: Answer-contract recovery](images/figure_28.png)

---

## Page 29 — Autonomous escalation resolver

Cell 25 targets every case still not committed after answer-contract recovery. It first applies a specialist solver to the committed top-5 evidence. If unresolved, it expands same-document evidence and tries again. Every candidate must still pass the independent answer verifier.

The recorded run started with 341 escalated cases. It ended with 682 total committed answers and 281 terminal escalations. Of those escalations, one was corpus-insufficient, 60 were stagnated and 220 were cycles. Technical failures were zero.

This stage demonstrates bounded autonomy rather than forced closure. The system can say, in machine-readable form, that it has exhausted its action policy. That is a stronger reliability property than generating something for every case while hiding uncertainty.

![Figure 29: Autonomous escalation resolver](images/figure_29.png)

---

## Page 30 — Validation routing after practical bounded resolver

Validation uses the 312-question document-disjoint validation split. Operational code receives question text, source-document identity and retrieval evidence. Gold answers are isolated until all predictions have been written durably. Explicit escalations count as unanswered or incorrect in all-case metrics rather than disappearing from the denominator.

The validation effort also became a stress test for computational practicality. Early attempts faithfully replayed the full introspective architecture and took hours for small numbers of cases. That behavior was unacceptable for a system intended to become practical. Instead of hiding the runtime, the lineage preserves those failed execution designs and the later simplifications.

This is why the repository distinguishes architectural correctness from production readiness. v0.1 establishes the control semantics. Runtime measurements identify which parts must be replaced before the system can become real-time.

The practical validation cell reuses the already-computed vector-search results. Stage 1 gives Qwen only the original top-5 evidence and asks for either a final answer or the literal signal `RETRIEVE`. This removes the observer, requirement verifier, query rewriter and specialist cascade from the first pass.

The stage still took 2 hours 26 minutes for 312 questions on the local RTX 4060 because Qwen generation dominated runtime. It answered 39 cases and routed 273 automatically to healing. The routing decision was autonomous; no person reviewed those cases.

The result is operationally disappointing but diagnostically useful. It confirms that reducing the *number of logical stages* is not enough when every case still requires a heavyweight autoregressive generation. Real efficiency requires moving more control decisions to deterministic code.

Stage 2 enriches evidence using same-document material and calls the model again only for cases marked `RETRIEVE`. It processed 273 cases in 2 hours 53 minutes. Only one additional case was committed after healing; 272 were escalated as insufficient.

That ratio is decisive. The expensive second-stage LLM solve produced almost no additional verified coverage. In the v0.1 execution regime, the healing prompt was not converting expanded evidence into useful answers efficiently enough to justify its cost.

A weak engineering response would keep tuning prompts inside the same architecture. The repository instead records the failure and uses it to redesign the next cost hierarchy: deterministic retrieval fusion first, deterministic verification where possible, one model solve, and at most one healing solve.

![Figure 30: Validation routing after practical bounded resolver](images/figure_30.png)

---

## Page 31 — Final validation quality

After the terminal resolver, the POC contains a prediction for all 312 validation questions. Thirty-nine are labeled `committed_fast_path`, one `committed_after_healing`, and 272 `committed_terminal_best_effort`. The last label is deliberately explicit: terminal coverage is not retroactively called verifier-certified closure.

The final normalized exact match is 0.2660 and mean token F1 is 0.5546. The complete v0.1 lineage accumulated 857 Qwen calls, averaging 2.747 calls per validation question. These metrics are frozen release facts.

The system is therefore not being released as a benchmark champion. It is being released as a complete autonomous control POC whose limitations are measured rather than hidden. A later version must improve both accuracy and cost while preserving the controller invariants.

![Figure 31: Final validation quality](images/figure_31.png)

---

## Page 32 — Validation runtime by stage

Validation runtime separates the architecture from the cost. Stage 1 averaged 25.45 seconds per case. Stage 2 averaged 36.29 seconds per healing case. The terminal resolver averaged 3.55 seconds per case. The evidence itself did not suddenly become ten times easier; the execution path became dramatically cheaper.

The bottleneck is repeated autoregressive inference, especially when the model is asked to observe, explain, rewrite, verify, repair and solve in separate calls. Each call rebuilds prompt context and incurs generation latency. Batching helps, but batching cannot rescue an architecture that asks the model to perform many control functions that deterministic code can perform more cheaply.

This result sets a hard v0.2 objective: model calls must be treated as a budgeted resource, not as a generic function call.

![Figure 32: Validation runtime by stage](images/figure_32.png)

---

## Page 33 — Accumulated Qwen calls through v0.1

The early controller used Qwen as both semantic sensor and actuator. It decomposed requirements, re-audited proposals, rewrote queries, generated answers, verified answers, repaired answers and performed specialist solving. This created a nested cascade: cases triggered requirements; requirements triggered verifier calls; failed verifiers triggered recovery; unresolved answers triggered further solvers.

The architecture was useful for discovering invariants because each component was explicit. It was terrible for latency. The validation experiments demonstrated that even GPU batching still left multi-hour stages.

The correct response is architectural compression, not abandonment. State, residual, transaction, rollback, cycle detection and checkpoints stay. The language-model call graph collapses.

![Figure 33: Accumulated Qwen calls through v0.1](images/figure_33.png)

---

## Page 34 — The terminal resolver exposed the efficient execution regime

The final POC resolver touches only the 272 unanswered validation cases. It does no Chroma query, no embedding pass, no observer loop and no verifier loop. It performs deterministic same-document micro-retrieval, preserves the 40 answers already obtained, and makes one short Qwen call per unresolved case.

This resolver completed all 272 cases in 15.82 minutes, approximately 3.55 seconds per case, starting with GPU batch 16. Its exact match on the resolver subset was 0.2537 and mean token F1 was 0.5338.

The speed difference is the central empirical result for engineering. The terminal resolver is not presented as a superior semantic verifier; it is a proof that the system can preserve document-local evidence discipline and obtain a practical execution regime when LLM introspection is removed. It is the bridge from v0.1 architecture to v0.2 implementation.

![Figure 34: The terminal resolver exposed the efficient execution regime](images/figure_34.png)

---

## Page 35 — Conventional RAG versus transactional self-healing RAG

A conventional RAG pipeline retrieves a fixed number of records and passes them to a generator. When the answer is wrong, at least three failure classes are entangled: the corpus may not contain the fact, the retriever may have missed it, or the generator may have failed to use evidence that was actually present. A single output score cannot distinguish these cases. Consequently, a conventional pipeline has no principled answer to the question “what should happen next?”

The v0.1 corpus makes that problem concrete. At the initial top-5 retrieval depth, requirement recall is only 45.80% on development, 46.37% on validation and 42.20% on test. Full-evidence rates are 48.49%, 48.40% and 46.60%. These are not rare edge cases. Roughly half of the questions enter generation without all evidence requirements represented in the top-5 set. Simply asking a stronger generator to “try harder” does not repair the retrieval state.

Self-healing begins by refusing to collapse all failure into answer error. Retrieval state is first-class. An answer can be withheld, repaired or escalated because the controller has an explicit representation of what remains unresolved.

Transactions are valuable whenever a repair can make part of a state better and another part worse. Retrieval has exactly this property. A rewritten query may recover one missing operand while losing the paragraph that supported another. A larger context may add the right table row but also add conflicting numbers from another period.

Without a transaction boundary, the system tends to overwrite context greedily. With a transaction boundary, candidate retrieval can be evaluated as a whole. The controller has a durable before-state, a tentative after-state and an acceptance test.

This perspective also makes debugging easier. A wrong answer can be traced to the last committed evidence state and the transaction history that produced it. The repository is therefore as much about observability as about correction.

![Figure 35: Conventional RAG versus transactional self-healing RAG](images/figure_35.png)

---

## Page 36 — Failure taxonomy

The dominant v0.1 failures fall into four groups. **Retrieval incompleteness** appears immediately in top-k requirement recall. **Semantic over-triggering** appears in the observer’s high recall but low specificity. **Serialization brittleness** appears in observer and answer JSON contract failures. **Execution cost** appears in the multi-hour validation stages.

A fifth category—**answer quality**—remains visible in the final 0.2660 exact match. Terminal coverage alone is not enough. The next system must ground answers better, especially numerical calculations and table structure.

These failure classes correspond to different repairs. Retrieval incompleteness calls for better candidate fusion. Over-triggering calls for cheaper or more specific diagnostics. Serialization brittleness calls for simpler contracts. Execution cost calls for fewer model calls. Answer quality calls for deterministic arithmetic and stronger evidence selection.

![Figure 36: Failure taxonomy](images/figure_36.png)

---

## Page 37 — Durable transaction log

The system records enough information to reconstruct why a case reached its terminal state: question UID, evidence IDs, requirement statuses, residuals, action, verifier result, commit decision and checkpoint timestamp. The exact schema evolved during development, but the principle remained constant.

Auditability is especially important when the controller is autonomous. Removing the human from the routing loop increases the need for post-hoc inspection, not the opposite. A production deployment should be able to answer: Which evidence was active? Which repair was tried? Why was it committed? Which invariant blocked a rejected proposal? Why did the case terminate?

The Markdown repository documents these semantics directly. The executed transcript supplies the implementation lineage behind them.

![Figure 37: Durable transaction log](images/figure_37.png)

---

## Page 38 — Checkpoint and restart semantics

Every major controller stage is restartable. Records are appended, flushed, `fsync`-ed and read back before the case is considered durable. On restart, completed question UIDs are recovered from the checkpoint and skipped.

This may appear mundane compared with retrieval algorithms, but it is essential to the meaning of a self-healing system. A controller that loses its state after a kernel restart is not persistent enough to claim autonomous recovery. Durability also made the week-long development process practical: successful work could be preserved while specific contract failures were recovered in later cells.

The repository therefore treats checkpoint logic as architecture, not boilerplate. It belongs beside residuals, repair operators and cycle detection because it determines whether the state machine survives real execution.

![Figure 38: Checkpoint and restart semantics](images/figure_38.png)

---

## Page 39 — Document-local repair boundary

Loop 2 exploits a fact available in the strict corpus: the source document UID is known. Once a question is associated with a source financial report, repair can search within that document rather than contaminating the state with globally similar records from unrelated companies.

This is particularly important in financial QA. Terms such as “current liabilities”, “research and development”, or “operating expenses” recur across many reports. Global semantic retrieval can return an excellent lexical match from the wrong company. Document-local repair prevents that failure by construction.

After verifier-failure recovery, Loop 2 recorded 233 commits and 345 rollbacks. Residual fell from 1,607 to 1,064, a reduction of 543, and the number of closed cases reached 557. The document boundary therefore produced substantial additional progress without relaxing the commit invariant.

The POC is not a security product, but several boundaries are already explicit. Gold answers are quarantined until scoring. Document-local repair blocks unrelated source documents once source identity is known. Persistent state is verified before use. Candidate evidence is not activated until verification.

A production system should extend these ideas to untrusted documents, prompt injection, provenance signatures and access control. In particular, a self-healing controller that automatically searches more sources can expand its attack surface if source trust is not modeled.

The transaction architecture is compatible with such controls because candidate evidence is already tentative. Source-policy checks can be inserted into the verifier before commit.

![Figure 39: Document-local repair boundary](images/figure_39.png)

---

## Page 40 — No human routing gate

A controller policy maps the current state to an ordered action list. In v0.1, states containing missing requirements prioritized lexical or targeted retrieval, while uncertainty could prioritize semantic reformulation. After a successful commit the controller rerouted from the new state. After failure it tried the next bounded action.

The key point is that this routing is automatic. The notebook prints diagnostics, but the human does not choose which loop to execute on a per-case basis. An autonomous controller is allowed to terminate with escalation. “Self-healing” does not mean forcing a fabricated answer; it means that the system itself carries the case as far as its action set and evidence permit.

The validation work later added a terminal best-effort resolver for POC coverage. That resolver is explicitly marked as best effort and is not confused with verified closure. The repository preserves both notions so later versions can improve quality without falsifying the v0.1 record.

![Figure 40: No human routing gate](images/figure_40.png)

---

## Page 41 — Gold-label isolation

Validation uses the 312-question document-disjoint validation split. Operational code receives question text, source-document identity and retrieval evidence. Gold answers are isolated until all predictions have been written durably. Explicit escalations count as unanswered or incorrect in all-case metrics rather than disappearing from the denominator.

The validation effort also became a stress test for computational practicality. Early attempts faithfully replayed the full introspective architecture and took hours for small numbers of cases. That behavior was unacceptable for a system intended to become practical. Instead of hiding the runtime, the lineage preserves those failed execution designs and the later simplifications.

This is why the repository distinguishes architectural correctness from production readiness. v0.1 establishes the control semantics. Runtime measurements identify which parts must be replaced before the system can become real-time.

![Figure 41: Gold-label isolation](images/figure_41.png)

---

## Page 42 — Action-cost ladder for the next implementation

The v0.2 work should proceed in an order determined by measured cost. First, precompute document-local dense matrices and lexical indexes. Second, fuse top-k evidence deterministically. Third, use one concise solver call. Fourth, verify extraction and arithmetic deterministically. Fifth, expand evidence and permit one more solve only on failure. Sixth, record the same transaction decision and durable terminal state as v0.1.

Only after this pipeline is fast should model size, fine-tuning or specialized rerankers be reconsidered. Premature model changes would confound the architectural speedup with a model swap.

The target is not simply a lower average runtime. It is a tight latency distribution with a hard bound on model calls.

![Figure 42: Action-cost ladder for the next implementation](images/figure_42.png)

---

## Page 43 — Development and validation are separated by document

The POC uses an exact TAT-DQA/TAT-QA bridge constructed into a strict local corpus. The frozen corpus contains 277 documents, 1,599 questions and 14,542 total units. Of those units, 3,838 paragraph and table-row records are active searchable evidence in Chroma.

The question split is document-disjoint: 963 development questions, 312 validation questions and 324 test questions. Document identity is assigned before question evaluation so that questions from the same source document do not cross the development/validation/test boundary.

This split matters because the controller is allowed to know a question’s source document during document-local repair. If the same source document appeared in both development and validation, a tuned document-level repair policy could leak structural information across the evaluation boundary. The split contract prevents that.

The frozen validation split should remain untouched for historical comparison. Development data can be used to tune retrieval-fusion weights, deterministic parsers and thresholds. A new version should report the same exact-match and token-F1 metrics, plus answer coverage, verified coverage, model calls per question, prompt tokens, output tokens, retrieval latency, verification latency and total wall-clock time.

Ablations should be operational rather than ornamental: vector only versus fused retrieval; LLM verifier versus deterministic verifier; one-call versus two-call cap; with and without document-local structural neighbors. Each ablation should report both quality and latency.

The central question becomes measurable: how much of v0.1’s autonomous healing behavior can be retained while removing expensive introspection?

![Figure 43: Development and validation are separated by document](images/figure_43.png)

---

## Page 44 — Error containment by rollback

Rollback is not an error path. It is a normal controller decision. When verification fails, residual does not strictly decrease, or a supported requirement regresses, the candidate state is discarded and the durable input state remains unchanged.

This means the controller can explore aggressively without corrupting its last known-good evidence. The system also records the rejected transaction, so a later controller can avoid repeating the same action under the same state signature.

The practical implication is large. Retrieval repair becomes safer because the cost of trying a candidate is bounded. A candidate can waste compute, but it cannot silently overwrite support that has already been verified. This property is one reason the architecture can be simplified in v0.2 without throwing away the v0.1 lineage: the invariant is independent of the particular retriever or language model used to propose the next state.

![Figure 44: Error containment by rollback](images/figure_44.png)

---

## Page 45 — Cycle signature

A healing loop can fail by returning to an evidence state it has already visited. The implemented controller stores signatures of active evidence-ID tuples. If a proposal recreates a seen signature, that branch is rejected rather than executed again.

The signature is simple:

$$\sigma(E)=(\operatorname{id}(e_1),\ldots,\operatorname{id}(e_k)).$$

This exact-state test does not detect every semantic cycle, but it prevents the most dangerous operational failure: an unbounded loop that repeatedly swaps or reconstructs the same top-k evidence. The final autonomous escalation resolver reported 220 cycle terminations, demonstrating that cycle handling is not theoretical decoration; it was exercised in the development lineage.

Future systems can strengthen the signature with canonicalized requirement support, retrieval-query hashes or semantic equivalence classes. Exact ID signatures are nevertheless enough to make v0.1 branches bounded and auditable.

![Figure 45: Cycle signature](images/figure_45.png)

---

## Page 46 — Bounded termination theorem

Termination follows from three implemented facts. The residual is a non-negative integer. Every committed transition strictly lowers it. The action set is bounded, and exact repeated evidence states are rejected. Therefore an individual controller branch cannot execute an infinite sequence of committed improvements, and it cannot execute an infinite sequence of identical non-improving proposals.

The terminal set contains both success and explicit failure states. Closure is success. Corpus insufficiency, stagnation, cycle and technical failure are explicit escalations. This distinction matters because a reliable system must not hide “could not repair” behind a generated answer.

The POC later adds a terminal best-effort answer stage to ensure every validation case has a prediction for scoring. That stage is outside the strict closure semantics. The repository labels those 272 cases `committed_terminal_best_effort`, preserving the difference between an operationally verified answer and a benchmark prediction produced for complete terminal coverage.

![Figure 46: Bounded termination theorem](images/figure_46.png)

---

## Page 47 — Latency model

A simple wall-clock model is

$$T \approx T_{\mathrm{index}} + N_s t_s + N_h t_h + T_{\mathrm{verify}},$$

where $N_s$ and $N_h$ are normal and healing model calls. In v0.1, $T_{\mathrm{index}}$ is small once embeddings and rankings are cached; repeated model generation dominates.

The terminal resolver result gives an empirical lower-complexity operating point: 272 cases in 15.82 minutes. That does not imply production speed is solved. It demonstrates that the hardware can process the workload at a useful rate when prompts are short and control logic is deterministic.

v0.2 should therefore measure tokens generated, prompt tokens, calls per case, retrieval time and verification time separately. A single wall-clock number is not enough to diagnose regression.

![Figure 47: Latency model](images/figure_47.png)

---

## Page 48 — v0.2 target architecture

The largest v0.2 opportunity is to move verification out of the language model whenever the task permits it. Financial QA contains many answers that are direct extractions or arithmetic expressions over explicit values. A deterministic verifier can check that cited evidence IDs exist, belong to the source document, contain the claimed operands, and reproduce the arithmetic result.

For an arithmetic candidate $y=f(x_1,\ldots,x_p)$, verification can require that every $x_i$ is grounded in the cited evidence and that an independent evaluator computes the same $y$ within the benchmark’s rounding rule. Units and percent scale can be checked separately.

This does not eliminate semantic verification for every question. It reduces the set of cases that require it. The principle is simple: use the model for language understanding, not for arithmetic a parser can perform exactly.

The terminal resolver showed that same-document micro-retrieval can be cheap. v0.2 should generalize this into deterministic retrieval fusion. The initial global vector top-k is retained, then augmented with same-document dense candidates, lexical candidates, neighboring table rows and neighboring paragraphs.

A fused candidate score can be written

$$F(e\mid q)=\alpha s_{\mathrm{dense}}+\beta s_{\mathrm{lex}}+\gamma s_{\mathrm{local}}+\delta s_{\mathrm{struct}},$$

where the terms represent semantic similarity, lexical overlap, source-document consistency and structural adjacency. The exact coefficients can be tuned on development only.

The aim is not to create another learned controller. The aim is to construct a compact high-recall evidence pool before the expensive model call begins.

The target execution contract is intentionally hard-bounded. For a normal case, deterministic retrieval fusion constructs evidence, one LLM call solves the question, and deterministic checks decide whether to commit. If checks fail, the evidence pool is expanded once and one additional solve is allowed. After that the case is explicitly escalated.

Thus

$$N_{\mathrm{LLM}}(q)\le 2$$

for the normal production path. The v0.1 average of 2.747 calls per validation question across the accumulated lineage is already close numerically, but the distribution and prompt lengths were inefficient. v0.2 makes the cap architectural rather than accidental.

The transaction invariants remain unchanged. A cheaper implementation is not allowed to bypass them.

![Figure 48: v0.2 target architecture](images/figure_48.png)

---

## Page 49 — Prior-art boundary: the claim is transactional self-healing

Self-RAG [9] trains a language model to retrieve, generate and critique through learned reflection tokens. It is a major predecessor for adaptive retrieval and self-reflection. Its central mechanism is model-internal reflection that controls retrieval and generation behavior.

The present system takes a different route. It does not train the generator to internalize a reflection policy. Instead, it externalizes state and control. Requirement status, residual, transaction decision, checkpoints and cycle memory live outside the model. The model can be replaced without changing the transaction semantics.

This difference is the basis of the repository’s novelty claim. The claim is not “Self-RAG did not self-correct.” It clearly did. The claim is that the present system turns healing into an explicit persistent transaction system rather than a learned reflective generation policy.

FLARE [8] demonstrates active retrieval during generation by anticipating future content and retrieving when low-confidence tokens indicate a need for more information. Unified Active Retrieval and later work broaden this idea. These systems establish that retrieval need not be a single pre-generation step.

Self-Healing RAG agrees with that premise but changes the control variable. Retrieval is triggered by unresolved requirement state and transaction policy rather than token uncertainty during generation. A repair proposal is then subject to commit/rollback.

The distinction matters because transaction semantics provide a durable notion of “better retrieval state” independent of the current generator’s token probabilities. In principle, a future implementation could use FLARE-like token uncertainty as one repair signal while retaining the same external transaction boundary.

CRAG [10] directly addresses the problem of incorrect retrieval. It evaluates retrieved documents, triggers corrective actions, uses web search as an extension, and decomposes/recomposes retrieved content. It is therefore one of the closest conceptual predecessors.

The present architecture differs in how correction is governed. CRAG uses a retrieval evaluator and confidence-driven action choice. Self-Healing RAG represents a multi-requirement state, computes a discrete residual, protects previously supported requirements and admits a candidate evidence state only through strict transactional commit. Rollback and durable transaction history are explicit architecture, not incidental implementation details.

This comparison is why the repository avoids the broad claim “first corrective RAG”. That would be false. The scoped claim is **first identified transactional self-healing RAG implementation** under the documented definition.

Self-Correcting RAG [17] combines context selection with NLI-guided MCTS to improve faithfulness. Reflective RAG [18] uses self-evaluation to optimize retrieval and generation strategy. ReflectiveRAG [19] addresses adaptivity and evidence redundancy. These 2026 systems make any vague claim of “first RAG that corrects itself” untenable.

They also sharpen the present contribution. The distinctive object here is not generic reflection. It is the explicit transition system with durable state. A proposal can be rolled back. A previously supported requirement is protected by invariant. A repeated evidence state is a cycle. A terminal escalation is a defined state. Those are systems semantics rather than merely reasoning behaviors.

The prior-art matrix in Figure 49 is intentionally scoped to these architectural properties.

The phrase “self-healing RAG” itself is not claimed as new. By 2026 it had appeared in tutorials, product descriptions and engineering discussions. The repository instead defines a technical boundary and states the claim against that boundary.

The boundary consists of six jointly required properties: explicit requirement state, discrete residual, strict commit/rollback, durable transaction history, cycle detection and bounded autonomous escalation. Earlier academic systems reviewed here contain important subsets—adaptive retrieval, self-critique, retrieval evaluation, strategy optimization, context selection—but the targeted search did not identify an earlier implementation combining the full transaction semantics.

This is the statement the repository is willing to defend. It is strong enough to matter and narrow enough to be checked.

Figure 49 gives a deliberately scoped comparison rather than a quality ranking. Self-RAG is credited with adaptive retrieval and self-reflection. FLARE is credited with active retrieval. CRAG is credited with retrieval evaluation and correction. Reflective and Self-Correcting RAG are credited with self-evaluation and corrective strategy.

The final row marks the properties claimed by this implementation: explicit residual, commit/rollback, durable transactions, cycle handling and bounded escalation in addition to adaptive repair. A dash in the matrix does not mean a predecessor is incapable of being implemented with that property; it means the cited method does not make that property the defining control architecture under comparison.

This careful interpretation prevents the matrix from becoming a straw-man novelty argument.

![Figure 49: Prior-art boundary: the claim is transactional self-healing](images/figure_49.png)

---

## Page 50 — Self-Healing RAG v0.1 complete POC map

v0.1 proves that RAG retrieval can be treated as a persistent controlled state rather than a one-shot context list. It demonstrates autonomous state observation, targeted repair, document-local repair, strict transaction commit, rollback, durable recovery, cycle detection, answer repair, bounded escalation and validation with gold-label isolation.

It also proves that these mechanisms can run on modest local hardware: an 8 GB RTX 4060 Laptop GPU with a 4-bit 7B instruction model. The system does not require a proprietary hosted model to execute its control logic.

Finally, it proves that the controller can survive its own implementation failures. Structured-output failures, verifier failures and interrupted runs were recovered without discarding successful prior state. That operational lineage is part of the release, not an embarrassment removed from the final artifact.

v0.1 does not establish state-of-the-art financial QA accuracy. An exact match of 0.2660 is not competitive with specialized systems. It does not establish production latency; the early validation stages are far too slow. It does not establish that Qwen-based semantic verification is better than deterministic verification. The terminal-resolver result suggests the opposite direction for engineering.

It also does not establish a universal decomposition scheme for every RAG task. The requirement representation is tested on financial document QA, where missing operands, periods, entities and units are natural atomic requirements.

These limits are stated because the architecture is easier to improve when its failures are explicit. The next versions should be judged against frozen v0.1 facts rather than a revised historical narrative.

The repository preserves inefficient loops because they establish the lineage of the architecture. Removing them would create a cleaner demo but destroy evidence about how the design was tested, where it failed, and which simplifications were justified by execution.

The correct versioning strategy is therefore additive. v0.1 freezes the complete proof of concept. v0.2 may introduce an efficient controller, but it should be compared against v0.1 rather than rewriting the history. Later releases can deprecate components operationally while retaining them as documented predecessors.

This is also why `EXECUTED_PIPELINE.md` is deliberately large. It is not intended as the first document a reader opens. It is the audit trail behind the concise architecture.

v0.1 is frozen as the first complete POC. Its results should not be silently replaced when later versions improve. The repository should tag or archive the exact release state associated with the Zenodo record, then continue development additively.

The release contract is therefore: preserve the executed lineage, preserve frozen metrics, document every architectural change, and never reinterpret best-effort terminal predictions as verified commits after the fact.

This makes the project cumulative. v0.2 can be much faster and more accurate while v0.1 remains the historical proof of the transaction architecture.

Self-Healing RAG v0.1 consists of five persistent ideas: **state**, **residual**, **repair**, **transaction**, and **termination**. Retrieval and answer-generation algorithms can change around those ideas without destroying the architecture.

The POC demonstrates the full loop on a difficult financial document QA setting, preserves every major failure and recovery step, validates on a document-disjoint split, and exposes both quality and runtime without hiding weaknesses. The final terminal resolver shows that the architecture can be driven into a practical execution regime when expensive LLM introspection is removed.

The next task is therefore not to invent another RAG diagram. It is to engineer this state machine until it becomes fast enough to run continuously: deterministic retrieval fusion, deterministic arithmetic verification, bounded model calls, strong provenance and the same strict commit semantics.

**The system is now defined. The remaining problem is engineering it hard enough that healing becomes cheaper than failure.**

![Figure 50: Self-Healing RAG v0.1 complete POC map](images/figure_50.png)

---

## References

See `REFERENCES.md` for the complete numbered bibliography with DOI/arXiv identifiers.
