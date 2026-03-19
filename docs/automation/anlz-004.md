# ANLZ-004: Composition Validation (Effect Coverage)

Verifies that primary scenario traces are complete and that traced subspecs collectively cover all effects declared in the primary scenario. Steps 1–2 (tag and BID existence) are fully mechanical. Steps 3–4 (effect extraction and coverage) are mechanical when Gherkin steps use effect-indicating vocabulary from the keyword table. Source: [inscribe.md](../stages/inscribe.md) (ANLZ-004 section).

## Constraint

**Steps 1–2 (traces tag presence, BID existence):** Always mechanical — no constraint.

**Steps 3–4 (effect coverage):** Mechanical when Gherkin Then/And and When steps use verbs from the effect vocabulary table below. When no effect vocabulary is detected in primary scenario steps:

```
status: SKIP
detail: "No effect vocabulary detected in primary scenario steps; mechanical effect coverage unavailable"
```

The effect vocabulary table is the mechanization lever: steps using listed verbs can be mechanically checked for coverage; steps using unlisted verbs require judgment.

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Primary spec | `tests/features/primary.feature` | Gherkin with `@BID-NNN` and `@traces` tags |
| Subspec files | `tests/features/{deliverable}.feature` | Gherkin with `@BID-NNN` tags |

### Gherkin Metadata Formats

**`@traces` tag** on primary spec scenarios (same format as ANLZ-003):
```gherkin
@BID-050 @traces:BID-003,BID-015,BID-024
Scenario: Full user workflow
```

**Effect extraction scope:** Then/And steps and When steps that contain effect verbs are effect candidates. Given steps are treated as context (preconditions) and excluded — per inscribe.md: "Given preconditions restating already-covered state are context, and context is excluded."

### Effect Vocabulary Table

| Category | Keywords | Effect type |
|----------|----------|-------------|
| Creation | creates, saves, stores, writes, generates, produces | `STATE_CREATED` |
| Change | updates, modifies, deletes, removes, clears, resets | `STATE_CHANGED` |
| Data flow | sends, returns, passes, forwards, emits, publishes | `DATA_FLOW` |
| Output | displays, renders, shows, prints, logs, responds | `OUTPUT` |

This table is extensible. Adding keywords follows the same pattern as default-value tables in [red-diagnostics.md](red-diagnostics.md): each new keyword maps to an existing effect type.

### Effect Extraction

For each primary scenario, collect Then/And step texts and When step texts. For each step, tokenize into words (lowercased) and match against the effect vocabulary table. A step containing one or more effect keywords produces one effect entry per matched keyword category (deduplicated by category per step).

## Behavior

```gherkin
Feature: ANLZ-004 Composition Validation
  Verifies primary scenario traces and effect coverage across subspecs.
  Steps 1–2 (tag/BID existence) are always mechanical.
  Steps 3–4 (effect coverage) require effect vocabulary in Gherkin steps.

  Background:
    Given the spec directory is "tests/features/"

  Rule: Traces tag presence — primary scenarios must have @traces tags

    Scenario: All primary scenarios have @traces tags
      Given "primary.feature" contains scenarios with @traces tags
      When the traces tag check runs
      Then no findings are produced

    Scenario: A primary scenario has no @traces tag
      Given "primary.feature" contains scenario "BID-050" without a @traces tag
      When the traces tag check runs
      Then the check status is FAIL
      And a finding is produced for "BID-050" with check_type "MISSING_TRACES"
      And the finding detail contains "has no @traces tag"

    Scenario: primary.feature does not exist
      Given "primary.feature" does not exist in the spec directory
      When the traces tag check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING_TRACES"
      And the finding detail is "primary.feature not found"

  Rule: Traced BID existence — every traced BID must resolve to a subspec

    Scenario: All traced BIDs resolve to subspecs
      Given primary scenario "BID-050" traces "BID-003, BID-015"
      And "BID-003" exists in subspec "users.feature"
      And "BID-015" exists in subspec "auth.feature"
      When the BID existence check runs
      Then no findings are produced

    Scenario: A traced BID does not exist in any subspec
      Given primary scenario "BID-050" traces "BID-099"
      And "BID-099" does not appear in any subspec file
      When the BID existence check runs
      Then the check status is FAIL
      And a finding is produced for "BID-050" with check_type "MISSING_BID"
      And the finding detail contains "traces BID-099 but BID not found in any subspec"

    Scenario: A traced BID resolves to primary.feature itself — skipped
      Given primary scenario "BID-050" traces "BID-051"
      And "BID-051" is in "primary.feature"
      When the BID existence check runs
      Then no finding is produced for the "BID-050" → "BID-051" trace

  Rule: Effect vocabulary gate — effect verbs must be present for coverage checking

    Scenario: No effect vocabulary in primary scenario steps
      Given primary scenario "BID-050" has Then steps with no effect keywords
      When the effect coverage check runs
      Then the check status is SKIP
      And the detail is "No effect vocabulary detected in primary scenario steps; mechanical effect coverage unavailable"

    Scenario: Effect vocabulary is present in primary scenario steps
      Given primary scenario "BID-050" has a Then step "Then the system creates a user record"
      When the effect coverage check runs
      Then the check proceeds to evaluate effect coverage

  Rule: Effect coverage — each primary effect must appear in at least one traced subspec

    Scenario: All effects are covered by traced subspecs
      Given primary scenario "BID-050" has Then step "Then the system creates a user record"
      And "BID-050" traces "BID-003"
      And "BID-003" in subspec "users.feature" has Then step "Then the user record is created"
      When the effect coverage check runs
      Then no findings are produced

    Scenario: An effect is not covered by any traced subspec
      Given primary scenario "BID-050" has Then step "Then the system sends a welcome email"
      And "BID-050" traces "BID-003"
      And "BID-003" in subspec "users.feature" has no steps with "sends" or DATA_FLOW keywords
      When the effect coverage check runs
      Then the check status is FAIL
      And a finding is produced for "BID-050" with check_type "UNCOVERED_EFFECT"
      And the finding detail contains "sends" and "DATA_FLOW"

    Scenario: Multiple uncovered effects produce independent findings
      Given primary scenario "BID-050" has Then step "Then the system creates a record and sends an email"
      And "BID-050" traces "BID-003"
      And "BID-003" has no steps with STATE_CREATED or DATA_FLOW keywords
      When the effect coverage check runs
      Then two findings are produced for "BID-050" with check_type "UNCOVERED_EFFECT"

    Scenario: Given steps are excluded from effect extraction
      Given primary scenario "BID-050" has Given step "Given the system stores a config"
      And "BID-050" has Then step "Then the system displays the dashboard"
      And "BID-050" traces "BID-003"
      And "BID-003" has Then step "Then the dashboard is displayed"
      When the effect coverage check runs
      Then no finding is produced for the "stores" verb in the Given step
      And the only effect checked is "displays" (OUTPUT)

    Scenario: When step with effect verb is included
      Given primary scenario "BID-050" has When step "When the system sends a notification"
      And "BID-050" has Then step "Then the status updates to sent"
      And "BID-050" traces "BID-003, BID-004"
      And "BID-003" has When step "When the notification is sent"
      And "BID-004" has Then step "Then the status is updated"
      When the effect coverage check runs
      Then no findings are produced
```

## Output

ANLZ-004 does not write a standalone inspection artifact. Its result is part of the Inscribe.Verify consistency check output, alongside ANLZ-001, ANLZ-002, and ANLZ-003. Implementations may emit the result to stdout for tooling use.

Results follow the standard Finding format:

```
Finding:
  bid          — the primary scenario BID
  check_type   — "MISSING_TRACES" | "MISSING_BID" | "UNCOVERED_EFFECT"
  detail       — specific issue: missing tag, unresolvable BID, or uncovered effect
                 with the effect keyword and type
```

## Edge Cases

- **Missing primary.feature:** The entire check fails with a `MISSING_TRACES` finding. Steps 3–4 are skipped.
- **Primary scenario with `@traces` but empty BID list:** `@traces:` with no BIDs after the colon produces no trace entries. The traces tag check passes (the tag exists); the BID existence check has nothing to check.
- **Effect keyword in both primary and subspec:** Coverage matching is by effect type category, not exact keyword. Primary step "creates" is covered by subspec step "produces" (both `STATE_CREATED`).
- **Multiple effect categories in one step:** A step like "creates a record and sends a notification" produces two effect entries (`STATE_CREATED`, `DATA_FLOW`). Each is checked independently for coverage.
- **Subspec step with effect verb in a Given clause:** Subspec Given steps are also excluded from effect extraction on the subspec side. Only Then/And and When steps with effect verbs count as covering an effect.
- **Effect vocabulary false positives:** A step like "Then the system returns an error" matches `DATA_FLOW` via "returns." This is an accepted limitation of keyword-based detection — precision is traded for recall on obvious gaps.
- **Overlap with ANLZ-003:** ANLZ-003 checks domain declarations; ANLZ-004 checks trace completeness and effect coverage. A subspec missing domains is an ANLZ-003 concern. A primary scenario missing traces is an ANLZ-004 concern.
