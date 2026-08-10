# Mathematical foundation

This file isolates the control mathematics from the implementation details. The central object is not the language model. It is a finite-state repair process over a durable retrieval state.

## 1. Operational state

For a question \(q\), define

$$
s=(q,E,R,h,\tau,\kappa),
$$

where:

- \(E=(e_1,\ldots,e_k)\) is the active ordered evidence tuple;
- \(R=(r_1,\ldots,r_m)\) is the frozen requirement vector;
- \(h\) is the set of previously visited evidence signatures;
- \(\tau\) is the durable transaction history;
- \(\kappa\) is the terminal/control status.

Each requirement is

$$
r_i=(i,d_i,z_i,G_i),
$$

with immutable identity \(i\), description \(d_i\), status \(z_i\), and a set \(G_i\) of supporting evidence-unit identifiers.

The status alphabet is

$$
Z=\{S,U,M\}
 =\{\text{supported},\text{uncertain},\text{missing}\}.
$$

A state is **closed** exactly when every requirement is supported.

## 2. Residual

Define the status cost

$$
c(S)=0,\qquad c(U)=1,\qquad c(M)=2.
$$

The residual is

$$
\rho(s)=\sum_{i=1}^{m}c(z_i).
$$

Therefore

$$
0\le \rho(s)\le 2m.
$$

### Lemma 1 — closure equivalence

A state is closed if and only if \(\rho(s)=0\).

**Proof.** Every summand is non-negative and equals zero only for status \(S\). Hence the sum is zero exactly when every status is \(S\). ∎

This is why the residual can act as a control objective without consulting the benchmark answer.

## 3. Supported-set invariant

Define

$$
\mathcal S(s)=\{i:z_i=S\}.
$$

The controller requires monotonic support on commit:

$$
\mathcal S(s)\subseteq\mathcal S(s').
$$

### Lemma 2 — support cannot disappear across committed transitions

Let \(s_0\to s_1\to\cdots\to s_t\) be a sequence of committed transitions. Then

$$
\mathcal S(s_0)\subseteq\mathcal S(s_1)\subseteq\cdots\subseteq\mathcal S(s_t).
$$

**Proof.** Apply the commit invariant at each adjacent transition and use transitivity of set inclusion. ∎

This property is the formal version of protected evidence. The implementation may replace a particular evidence record, but only if the same requirement remains verified as supported in the candidate state.

## 4. Repair action

Let \(\mathcal A(s)\) denote the bounded list of actions available in state \(s\). An action

$$
a\in\mathcal A(s)
$$

produces a tentative proposal

$$
p=P(s,a).
$$

The proposal is not yet active state. It is speculative state awaiting verification.

Examples of actions in v0.1 include requirement-targeted retrieval, document-local retrieval, lexical search, rewritten semantic retrieval, evidence expansion and specialist solving.

## 5. Verification map

The verifier maps the proposal into a candidate audited state

$$
V:(q,p,R)\mapsto \hat s.
$$

The crucial restriction is that \(R\) is frozen. The verifier may update statuses and supporting evidence IDs, but it may not change the requirement identities or delete requirements in order to make the residual easier to reduce.

## 6. Transaction

A transaction is

$$
T=(s,a,p,\hat s,d,s^*),
$$

where \(d\in\{\mathrm{commit},\mathrm{rollback}\}\).

The decision rule is

$$
d=\mathrm{commit}
\iff
\rho(\hat s)<\rho(s)
\ \land\
\mathcal S(s)\subseteq\mathcal S(\hat s).
$$

If the condition is false,

$$
d=\mathrm{rollback},\qquad s^*=s.
$$

If it is true,

$$
s^*=\hat s.
$$

### Proposition 1 — rollback safety

A rejected candidate cannot alter the durable state.

**Proof.** By definition of rollback, \(s^*=s\). The candidate proposal and its verifier output remain transaction records but do not become active state. ∎

### Proposition 2 — strict residual descent

For every committed transition \(s\to s'\),

$$
\rho(s')\le \rho(s)-1.
$$

**Proof.** The residual is integer-valued and commit requires \(\rho(s')<\rho(s)\). Therefore the difference is at least one. ∎

## 7. Bound on number of commits

Since \(0\le\rho(s)\le 2m\), Proposition 2 implies an immediate bound.

### Theorem 1 — finite commit depth

Starting from state \(s_0\), the number of committed retrieval-repair transitions is at most \(\rho(s_0)\), and therefore at most \(2m\).

**Proof.** Each commit decreases the non-negative integer residual by at least one. No more than \(\rho(s_0)\) such decreases are possible. ∎

This does not alone bound failed proposals. Failed proposals are handled by the bounded action set and cycle detector.

## 8. Exact cycle detection

For evidence tuple \(E\), define the signature

$$
\sigma(E)=\bigl(\operatorname{id}(e_1),\ldots,\operatorname{id}(e_k)\bigr).
$$

The visited-signature set after time \(t\) is

$$
h_t=\{\sigma(E_0),\ldots,\sigma(E_t)\}.
$$

A proposal \(E'\) satisfying

$$
\sigma(E')\in h_t
$$

is rejected as an exact cycle before it can create another active state.

The detector is intentionally exact rather than semantic. It guarantees rejection of literal evidence-state loops. Future versions may add semantic equivalence signatures, but exact detection is sufficient for the v0.1 termination argument.

## 9. Bounded branch termination

Assume a finite action budget

$$
|\mathcal A(s)|\le B
$$

for every state, and assume no action is retried indefinitely without a state change.

### Theorem 2 — controller termination

Every controller branch terminates after finitely many repair attempts in either a closed state or an explicit escalation state.

**Proof.** By Theorem 1, there are finitely many committed transitions. Between any two commits, at most \(B\) bounded actions are attempted. Exact evidence-state cycles are rejected. Therefore a branch cannot contain infinitely many committed transitions and cannot contain infinitely many non-committed transitions between commits. It must terminate. ∎

An explicit escalation is therefore not an implementation accident. It is part of the terminal state space required by the theorem.

## 10. Transaction log as a state reconstruction object

Let transactions be ordered

$$
\tau=(T_1,T_2,\ldots,T_n).
$$

Because every transaction stores its decision and post-transaction durable state, the active state after transaction \(j\) is reconstructible from the prefix

$$
\tau_{1:j}.
$$

This is the formal reason checkpoint/restart semantics belong to the architecture: durable recovery is a replay or resume operation over a finite transaction prefix.

## 11. Gold isolation

Let \(G\) denote benchmark gold answers and requirement labels. Operational state transitions satisfy

$$
s_{t+1}=F(s_t,a_t;q,\mathcal C,\theta),
$$

where \(\mathcal C\) is the corpus and \(\theta\) denotes model/retriever parameters. Gold \(G\) is not an argument of \(F\).

Only after the prediction map \(P\) is durably frozen is the evaluation function invoked:

$$
\operatorname{score}(P,G).
$$

The design therefore separates control information from benchmark supervision.

## 12. Document-local repair constraint

When the source-document identifier \(D(q)\) is known, define the admissible repair corpus

$$
\mathcal C_q=\{e\in\mathcal C:\operatorname{doc}(e)=D(q)\}.
$$

A document-local repair operator must satisfy

$$
P(s,a).E\subseteq \mathcal C_q\cup E_{\mathrm{protected}}.
$$

This prevents a semantically similar record from another company or report from contaminating the repaired state.

## 13. Retrieval-fusion target for v0.2

A deterministic fused score can be written

$$
F(e\mid q)
=\alpha s_{\mathrm{dense}}(e,q)
+\beta s_{\mathrm{lex}}(e,q)
+\gamma s_{\mathrm{local}}(e,q)
+\delta s_{\mathrm{struct}}(e,q).
$$

The individual terms can encode cosine similarity, lexical overlap, source-document consistency, and table/paragraph adjacency. The transaction semantics do not depend on the exact choice of \(F\).

## 14. Deterministic arithmetic verification

Suppose a candidate answer is represented as

$$
y=f(x_1,\ldots,x_p),
$$

where the operands are extracted from cited evidence. A deterministic verifier accepts the arithmetic component only if:

1. every \(x_i\) is grounded in an admissible evidence unit;
2. units and scale are compatible with the question;
3. an independent evaluator computes \(f(x_1,\ldots,x_p)\);
4. the computed value matches \(y\) under the benchmark rounding rule.

This can remove a large class of expensive language-model verification calls.

## 15. Bounded-call v0.2 contract

The production target imposes

$$
N_{\mathrm{LLM}}(q)\le 2.
$$

The first call solves from the deterministic fused pool. A second call is permitted only if deterministic verification fails and a bounded evidence-expansion transaction creates a new candidate pool.

The expected wall-clock cost can be decomposed as

$$
T(q)=T_{\mathrm{retrieve}}(q)
+N_{\mathrm{LLM}}(q)t_{\mathrm{LLM}}
+T_{\mathrm{verify}}(q)
+T_{\mathrm{durable}}(q).
$$

v0.1 measurements show that reducing \(N_{\mathrm{LLM}}\) and shortening prompts dominate the immediate optimization opportunity.

## 16. Compatibility invariants for later versions

Later versions remain compatible with the v0.1 architecture only if the following continue to hold:

$$
\begin{aligned}
&\text{I1: } G \notin F(\cdot) \quad \text{during operation},\\
&\text{I2: rollback leaves durable state unchanged},\\
&\text{I3: }\mathcal S(s)\subseteq\mathcal S(s')\quad\text{on commit},\\
&\text{I4: every branch terminates finitely},\\
&\text{I5: every completed case has durable terminal state}.
\end{aligned}
$$

These invariants define the system more fundamentally than any specific language model, vector database or prompt.
