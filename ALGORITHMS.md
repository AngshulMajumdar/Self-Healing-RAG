# Algorithms

## Algorithm 1 — transactional retrieval repair

```text
INPUT: durable state s
for action a in controller_policy(s):
    p = propose(s, a)
    if signature(p.evidence) already seen:
        continue
    v = verify_frozen_requirements(p)
    if residual(v) < residual(s) and no_supported_requirement_regresses(s, v):
        commit v atomically
        checkpoint
        return v
    else:
        rollback p
return explicit_retrieval_escalation(s)
```

## Algorithm 2 — autonomous controller

```text
while state is open:
    next_state = transactional_repair(state)
    if next_state is a committed improvement:
        state = next_state
        continue
    if action budget exhausted or cycle detected:
        mark terminal escalation
        break
return state
```

## Algorithm 3 — answer generation and recovery

```text
candidate = solve(question, committed_evidence)
verdict = verify(candidate, committed_evidence)
if verdict == PASS:
    commit answer
elif verdict == REPAIR:
    candidate = bounded_repair(candidate)
    verify again
else:
    escalate
```

## Algorithm 4 — practical v0.2 target

```text
pool = deterministic_retrieval_fusion(question)
answer = LLM_SOLVE(pool)                       # call 1
check = deterministic_verify(answer, pool)
if check passes:
    commit
else:
    healed_pool = deterministic_expand(pool)
    answer = LLM_SOLVE(healed_pool)             # call 2, only if needed
    check = deterministic_verify(answer, healed_pool)
    if check passes:
        commit
    else:
        explicit escalation
```

The fourth algorithm is not allowed to weaken the v0.1 transaction invariants. It changes the cost of observation and verification, not the meaning of commit.
