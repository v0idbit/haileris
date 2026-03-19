# Second-Reader Test: Assertion Correction Verification

Independently derives expected assertion values from Gherkin steps and Arrange data, then compares against proposed corrections. This runs during Settle.Fix (test tier 2 — assertion-level corrections), not during an inspection stage. Source: [settle.md](../stages/settle.md) (Settle.Fix / test tier 2).

## Constraint

**Condition:** The Gherkin Then/And step contains a formulaic relationship pattern from the table below, and the operands referenced in the pattern are available in the test's Arrange section data.

The derivation is mechanical for formulaic relationships (sum, count, max, etc.). For qualitative or relational relationships that require judgment (e.g., "the user should be satisfied", "the result should be appropriate"):

```
status: SKIP
detail: "No formulaic relationship pattern detected; mechanical second-reader derivation unavailable"
```

When a formulaic pattern is detected but operands are missing from the Arrange data:

```
status: SKIP
detail: "Formulaic pattern detected but operands not available in Arrange data; mechanical derivation unavailable"
```

## Inputs

| Input | Path | Format |
|-------|------|--------|
| BID reference | From Settle.Fix context | BID identifier |
| Gherkin step | From spec file (`tests/features/*.feature`) | Then/And step text |
| Arrange section data | From test source file | Variable assignments in Arrange section |
| Proposed correction | From Settle.Fix output | New assertion expected value |

**Closed derivation scope:** The second-reader derives its expected value from exactly two sources: the Gherkin step text and the test's Arrange section data. Only these two sources are consulted — production code, external data, and prior step results are outside the derivation boundary. This closed scope keeps the derivation independent: it is isolated from the same errors that produced the proposed correction.

## Formulaic Relationship Patterns

| Pattern | Gherkin indicators | Computation |
|---------|-------------------|-------------|
| Sum | "sum of", "total of", "adds up to" | `sum(operands)` |
| Count | "count of", "number of" | `len(collection)` |
| Max | "maximum of", "highest of" | `max(collection)` |
| Min | "minimum of", "lowest of" | `min(collection)` |
| Average | "average of", "mean of" | `sum(operands) / len(operands)` |
| Concatenation | "concatenation of", "joined" | `concat(operands)` |
| Difference | "difference between" | `a - b` |
| Product | "product of", "multiplied by" | `a * b` |
| Boolean | "all of", "any of", "none of" | `all / any / not any` |
| Membership | "contains", "includes" | `element in collection` |
| Length | "length of", "size of" | `len(value)` |

This table is extensible. Adding patterns follows the same convention as other vocabulary tables: each new indicator maps to a computation type.

### Pattern Matching

Gherkin step text is scanned for indicator phrases (case-insensitive). The first matching pattern determines the computation type. If multiple patterns match, the longest indicator phrase wins. Operand names are extracted from the surrounding step text and resolved against Arrange section variable names.

### Operand Resolution

Operands referenced in the Gherkin step are resolved to values from the test's Arrange section. Resolution uses exact name matching (case-sensitive) against variable assignment left-hand sides. Unresolvable operands trigger SKIP for that BID.

## Behavior

```gherkin
Feature: Second-Reader Test
  Independently derives expected assertion values from Gherkin steps and
  Arrange data during Settle.Fix, then compares against proposed corrections.

  Rule: Constraint gate — a formulaic pattern must be present and operands available

    Scenario: No formulaic pattern in Gherkin step
      Given "BID-001" has Then step "Then the user sees a friendly greeting"
      And a proposed correction value of "Hello, Alice"
      When the second-reader check runs
      Then the check status is SKIP
      And the detail is "No formulaic relationship pattern detected; mechanical second-reader derivation unavailable"

    Scenario: Formulaic pattern found and operands available
      Given "BID-001" has Then step "Then the total of line items adds up to 150"
      And the Arrange section defines "line_items" as [50, 60, 40]
      And a proposed correction value of 150
      When the second-reader check runs
      Then the check proceeds to independent derivation

    Scenario: Formulaic pattern found but operands missing from Arrange
      Given "BID-001" has Then step "Then the sum of payments equals the invoice total"
      And the Arrange section does not define "payments"
      When the second-reader check runs
      Then the check status is SKIP
      And the detail is "Formulaic pattern detected but operands not available in Arrange data; mechanical derivation unavailable"

  Rule: Independent derivation — compute expected value and compare to proposed correction

    Scenario: Derived value matches proposed correction
      Given "BID-001" has Then step "Then the sum of prices equals the total"
      And the Arrange section defines "prices" as [10, 20, 30]
      And a proposed correction value of 60
      When the second-reader check runs
      Then the check status is PASS
      And the derived value is 60
      And the proposed correction is verified

    Scenario: Derived value does not match proposed correction
      Given "BID-001" has Then step "Then the sum of prices equals the total"
      And the Arrange section defines "prices" as [10, 20, 30]
      And a proposed correction value of 50
      When the second-reader check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "DERIVATION_MISMATCH"
      And the finding detail contains expected value 60 and proposed value 50

    Scenario: Sum derivation
      Given "BID-002" has Then step "Then the total of order amounts adds up to the grand total"
      And the Arrange section defines "order_amounts" as [100, 250, 75]
      And a proposed correction value of 425
      When the second-reader check runs
      Then the derived value is 425
      And the check status is PASS

    Scenario: Count derivation
      Given "BID-003" has Then step "Then the number of active users is 3"
      And the Arrange section defines "active_users" as ["alice", "bob", "carol"]
      And a proposed correction value of 3
      When the second-reader check runs
      Then the derived value is 3
      And the check status is PASS

    Scenario: Boolean derivation
      Given "BID-004" has Then step "Then all of the flags are set"
      And the Arrange section defines "flags" as [true, true, true]
      And a proposed correction value of true
      When the second-reader check runs
      Then the derived value is true
      And the check status is PASS

  Rule: User notification — verification results are communicated per settle.md

    Scenario: Proposed correction is verified
      Given the second-reader check produces PASS for "BID-001"
      When the notification is generated
      Then the notification includes the BID, the change description, and "verified"

    Scenario: Proposed correction is rejected
      Given the second-reader check produces FAIL for "BID-001"
      And the derived value is 60
      And the proposed value is 50
      When the notification is generated
      Then the notification includes the BID, the Gherkin step text, Arrange values used
      And the notification includes expected value 60 and proposed value 50

    Scenario: Derivation is skipped — no notification
      Given the second-reader check produces SKIP for "BID-001"
      When the notification step runs
      Then no notification is generated for "BID-001"
```

## Output

The second-reader test result is part of the Settle.Fix output for test tier 2 corrections. Unlike inspection-stage checks, this check produces user-facing notifications per [settle.md](../stages/settle.md) requirements.

Results follow the standard Finding format:

```
Finding:
  bid          — the BID whose assertion correction is being verified
  check_type   — "DERIVATION_MISMATCH"
  detail       — Gherkin step, Arrange values, derived expected value, proposed correction value
```

### User Notification Format

Each verification result produces a notification (PASS or FAIL only; SKIP produces no notification):

```
Notification:
  bid          — BID identifier
  step         — Gherkin Then/And step text
  arrange      — Arrange data values used in derivation
  derived      — independently derived expected value
  proposed     — proposed correction value
  status       — "verified" | "rejected"
```

## Edge Cases

- **Floating-point comparison:** For Average and other division-based patterns, implementations should use a tolerance (e.g., 1e-9) rather than exact equality. The tolerance should be documented.
- **String concatenation order:** For Concatenation patterns, operand order follows their appearance in the Gherkin step text, left to right. If order is ambiguous, the check emits SKIP for that derivation.
- **Empty collections:** `sum([])` = 0, `len([])` = 0, `all([])` = true, `any([])` = false. These follow standard semantics.
- **Multiple Then/And steps per BID:** Each step with a proposed correction is checked independently. A single BID may produce multiple PASS, FAIL, or SKIP results.
- **Nested operands:** If the Arrange section defines `order.items` but the Gherkin references "items," resolution by exact name match fails. The check emits SKIP. Implementations may optionally support dotted path resolution, but this is not required.
- **Type coercion:** The derived value and proposed correction are compared after type normalization (e.g., integer 60 equals float 60.0). String-to-number coercion is not performed — `"60"` does not match `60`.
- **Arrange values modified by Act:** The second-reader uses Arrange values as written, not as potentially modified by the Act section. This is intentional — the derivation must be independent of production code behavior.
