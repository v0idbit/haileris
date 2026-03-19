# ANLZ-001: Contradiction Detection (Verification Layer)

Checks a set of typed propositions for logical contradictions. The propositions are produced from Gherkin steps by a judgment-dependent translation step (out of scope). This spec defines only the mechanical verification: given propositions, detect contradictions. Source: [inscribe.md](../stages/inscribe.md) (ANLZ-001 section).

## Constraint

**Condition:** A set of typed propositions has been produced from Gherkin steps.

Proposition extraction (translating Gherkin steps to typed propositions) requires judgment and is out of scope for this spec. This spec activates only when propositions are available as input.

When no propositions exist:

```
status: SKIP
detail: "No typed propositions available; mechanical contradiction detection unavailable"
```

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Proposition set | Implementation-defined | Typed propositions (see format below) |
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags (traceability) |

### Proposition Format

Each proposition captures a single behavioral claim extracted from a Gherkin step:

```
Proposition:
  bid        — source BID (e.g., "BID-001")
  step       — Gherkin step text (traceability back to spec)
  subject    — entity name (e.g., "user", "session", "balance")
  relation   — REQUIRES_STATE | PRODUCES_STATE | FORBIDS_STATE |
               CREATES | DELETES | MUTATES | READS
  object     — state or value (e.g., "active", "logged_in", "> 100")
```

This format is the contract between the judgment-dependent translation step and this mechanical verification layer. Any implementation that produces propositions conforming to this schema can use this checker.

## Contradiction Rules

The following rules define contradictions. Implementation may use a constraint solver (e.g., Z3) or pairwise comparison — the behavioral result is the same.

### Pairwise State Contradictions

Two propositions contradict when they assert incompatible states for the same subject and object:

- `REQUIRES_STATE(subject, object)` vs. `FORBIDS_STATE(subject, object)` — one BID requires a state that another forbids
- `CREATES(subject, object)` vs. `DELETES(subject, object)` within the same execution scope — one BID creates what another deletes

Same-subject, different-object propositions are compatible (e.g., `REQUIRES_STATE(user, active)` and `REQUIRES_STATE(user, verified)` are compatible).

### Numeric Bound Contradictions

Propositions with numeric bound objects contradict when their bounds are unsatisfiable:

- `PRODUCES_STATE(subject, "> N")` vs. `REQUIRES_STATE(subject, "<= N")` — one BID produces a value above N while another requires it at or below N
- Applies symmetrically to all bound combinations where the intersection is empty

Different subjects with conflicting bounds are compatible.

### Transitive Contradictions

Contradictions that emerge through state chains across BIDs:

- BID-A `PRODUCES_STATE(subject, X)`, BID-B `REQUIRES_STATE(subject, X)` and `PRODUCES_STATE(subject, Y)`, BID-C `FORBIDS_STATE(subject, Y)` — the chain A→B→C produces a transitive contradiction

Transitive detection follows state production/requirement chains up to the full proposition set. Implementation may limit chain depth for performance, but must document the limit.

## Behavior

```gherkin
Feature: ANLZ-001 Contradiction Detection
  Checks typed propositions for logical contradictions between BIDs.
  The judgment-dependent translation step (Gherkin → propositions) is out of scope.

  Rule: Constraint gate — typed propositions must be available

    Scenario: No propositions have been produced
      Given no typed propositions exist for the feature
      When the contradiction detection check runs
      Then the check status is SKIP
      And the detail is "No typed propositions available; mechanical contradiction detection unavailable"

    Scenario: Propositions exist but the set is empty
      Given the proposition set exists but contains zero propositions
      When the contradiction detection check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: Propositions are available
      Given the proposition set contains one or more propositions
      When the contradiction detection check runs
      Then the check proceeds to evaluate contradiction rules

  Rule: Pairwise state contradictions — REQUIRES vs FORBIDS, CREATES vs DELETES

    Scenario: Compatible propositions — no contradiction
      Given "BID-001" has proposition REQUIRES_STATE(user, active)
      And "BID-002" has proposition REQUIRES_STATE(user, verified)
      When the contradiction detection check runs
      Then no findings are produced

    Scenario: REQUIRES_STATE vs FORBIDS_STATE on same subject and object
      Given "BID-001" has proposition REQUIRES_STATE(session, active)
      And "BID-002" has proposition FORBIDS_STATE(session, active)
      When the contradiction detection check runs
      Then the check status is FAIL
      And a finding is produced with check_type "CONTRADICTION"
      And the finding detail references "BID-001" and "BID-002"
      And the finding detail contains the contradicting propositions

    Scenario: CREATES vs DELETES on same subject and object
      Given "BID-003" has proposition CREATES(account, premium)
      And "BID-004" has proposition DELETES(account, premium)
      When the contradiction detection check runs
      Then the check status is FAIL
      And a finding is produced with check_type "CONTRADICTION"
      And the finding detail references "BID-003" and "BID-004"

    Scenario: Same subject, different objects — compatible
      Given "BID-001" has proposition REQUIRES_STATE(user, active)
      And "BID-002" has proposition FORBIDS_STATE(user, suspended)
      When the contradiction detection check runs
      Then no findings are produced

    Scenario: Multiple contradicting pairs produce independent findings
      Given "BID-001" has proposition REQUIRES_STATE(session, active)
      And "BID-002" has proposition FORBIDS_STATE(session, active)
      And "BID-003" has proposition CREATES(token, valid)
      And "BID-004" has proposition DELETES(token, valid)
      When the contradiction detection check runs
      Then two findings are produced with check_type "CONTRADICTION"

  Rule: Numeric bound contradictions — unsatisfiable value ranges

    Scenario: Compatible numeric bounds
      Given "BID-005" has proposition PRODUCES_STATE(balance, "> 100")
      And "BID-006" has proposition REQUIRES_STATE(balance, "> 50")
      When the contradiction detection check runs
      Then no findings are produced

    Scenario: Unsatisfiable numeric bounds
      Given "BID-005" has proposition PRODUCES_STATE(balance, "> 100")
      And "BID-006" has proposition REQUIRES_STATE(balance, "<= 100")
      When the contradiction detection check runs
      Then the check status is FAIL
      And a finding is produced with check_type "CONTRADICTION"
      And the finding detail references "BID-005" and "BID-006"
      And the finding detail contains the unsatisfiable bound pair

    Scenario: Different subjects with conflicting bounds — compatible
      Given "BID-005" has proposition PRODUCES_STATE(balance, "> 100")
      And "BID-006" has proposition REQUIRES_STATE(limit, "<= 100")
      When the contradiction detection check runs
      Then no findings are produced

  Rule: Transitive contradictions — state chains across BIDs

    Scenario: Chain produces transitive contradiction
      Given "BID-007" has proposition PRODUCES_STATE(order, confirmed)
      And "BID-008" has proposition REQUIRES_STATE(order, confirmed)
      And "BID-008" has proposition PRODUCES_STATE(order, shipped)
      And "BID-009" has proposition FORBIDS_STATE(order, shipped)
      When the contradiction detection check runs
      Then the check status is FAIL
      And a finding is produced with check_type "CONTRADICTION"
      And the finding detail references the full chain "BID-007" → "BID-008" → "BID-009"

    Scenario: Chain without contradiction
      Given "BID-007" has proposition PRODUCES_STATE(order, confirmed)
      And "BID-008" has proposition REQUIRES_STATE(order, confirmed)
      And "BID-008" has proposition PRODUCES_STATE(order, shipped)
      And "BID-009" has proposition REQUIRES_STATE(order, shipped)
      When the contradiction detection check runs
      Then no findings are produced
```

## Output

ANLZ-001 does not write a standalone inspection artifact. Its result is part of the Inscribe.Verify consistency check output, alongside ANLZ-002. Implementations may emit the result to stdout for tooling use.

Results follow the standard Finding format:

```
Finding:
  bid          — both BID identifiers involved in the contradiction
  check_type   — "CONTRADICTION"
  detail       — the contradicting propositions, their source BIDs, and the contradiction type
                 (pairwise, numeric, or transitive with full chain)
```

## Edge Cases

- **Single proposition:** A single proposition is always self-consistent under these rules. The check produces PASS.
- **Same BID, contradicting propositions:** A BID that both REQUIRES and FORBIDS the same state on the same subject is a self-contradiction. This is flagged the same as a cross-BID contradiction.
- **Transitive chain depth:** Implementations may limit chain depth for performance. Any limit must be documented and should be at least 3 (direct → intermediate → conflicting).
- **Partial proposition sets:** If only some Gherkin steps were translated to propositions, the check runs on what is available. Unrepresented steps are not flagged — they are outside the verification boundary.
- **MUTATES and READS relations:** These relations are excluded from contradiction rules. They are included in the proposition format for completeness and may support future analysis.
- **Duplicate propositions:** Multiple propositions with identical fields are treated as one. Deduplication happens before contradiction checking.
