# Layout Inspection

Validates subspecs against primary spec BIDs. Source: [layout.md](../stages/layout.md) (Layout Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Primary spec | `tests/features/primary.feature` | Gherkin with `@BID-NNN` tags |
| Subspec files | `tests/features/{deliverable}.feature` | Gherkin with `@BID-NNN` tags |

### BID Extraction

Primary spec BIDs are extracted by scanning `primary.feature` for `@BID-NNN` tags (regex `@(BID-\d+)`). The result is a set of unique BID identifiers.

Subspec BIDs are extracted by scanning all `.feature` files except `primary.feature` for `@BID-NNN` tags. The result is a set of unique BID identifiers, each associated with its parent subspec file.

### Subspec Parsing

Each subspec file (`{deliverable}.feature`, excluding `primary.feature`) contributes:
- **file**: the subspec filename (e.g., `users.feature`)
- **description**: the Feature description text (the line(s) after the `Feature:` keyword)
- **bids**: unique set of all `BID-\d+` matches from `@BID-NNN` tags in the file

The union of all subspec BIDs across all subspecs forms the `subspec_bids` set.

## Behavior

```gherkin
Feature: Layout Inspection
  Validates subspecs against primary spec BIDs across 5 dimensions.

  Background:
    Given the primary spec is at "tests/features/primary.feature"
    And subspec files are in "tests/features/" (excluding primary.feature)

  Rule: MISSING — every primary spec BID must appear in at least one subspec

    Scenario: All primary spec BIDs appear in subspecs
      Given the primary spec contains BIDs "BID-001, BID-002"
      And subspecs collectively reference BIDs "BID-001, BID-002"
      When the MISSING check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A primary spec BID is absent from all subspecs
      Given the primary spec contains BIDs "BID-001, BID-002"
      And subspecs collectively reference BIDs "BID-001"
      When the MISSING check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "MISSING"
      And the finding detail is "BID-002 has no subspec coverage"

    Scenario: Multiple missing BIDs are reported in sorted order
      Given the primary spec contains BIDs "BID-001, BID-002, BID-003"
      And subspecs collectively reference BIDs "BID-002"
      When the MISSING check runs
      Then the check status is FAIL
      And findings are produced for "BID-001, BID-003" with check_type "MISSING"
      And findings are reported in sorted BID order

  Rule: HALLUCINATED — every subspec BID must have a corresponding primary spec entry

    Scenario: All subspec BIDs exist in the primary spec
      Given the primary spec contains BIDs "BID-001, BID-002"
      And subspecs collectively reference BIDs "BID-001, BID-002"
      When the HALLUCINATED check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A subspec references a BID not in the primary spec
      Given the primary spec contains BIDs "BID-001"
      And subspecs collectively reference BIDs "BID-001, BID-002"
      When the HALLUCINATED check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "HALLUCINATED"
      And the finding detail is "BID-002 is in subspecs but not in primary spec"

  Rule: DUPLICATED — a BID should appear in only one subspec

    Scenario: Each BID appears in exactly one subspec
      Given "users.feature" references BIDs "BID-001"
      And "auth.feature" references BIDs "BID-002"
      When the DUPLICATED check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A BID appears in multiple subspecs
      Given "users.feature" references BIDs "BID-001"
      And "auth.feature" references BIDs "BID-001"
      When the DUPLICATED check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "DUPLICATED"
      And the finding detail is "BID-001 appears in 2 subspecs"

  Rule: INSUFFICIENT — subspec Feature descriptions must be substantive and related to their BIDs

    Scenario: A subspec Feature description has 10+ words and shares keywords with its BID scenarios
      Given "users.feature" has a Feature description with 12 words
      And "users.feature" references BIDs "BID-001"
      And the Gherkin steps for "BID-001" share keywords with the Feature description
      When the INSUFFICIENT check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A subspec Feature description has fewer than 10 words
      Given "users.feature" has a Feature description with 5 words
      When the INSUFFICIENT check runs
      Then the check status is FAIL
      And a finding is produced for "users.feature" with check_type "INSUFFICIENT"
      And the finding detail contains "users.feature Feature description has 5 words (need ≥10)"

    Scenario: A subspec Feature description shares no keywords with its BID scenarios
      Given "users.feature" has a Feature description with 15 words
      And "users.feature" references BIDs "BID-001"
      And the Gherkin steps for "BID-001" share no keywords with the Feature description
      When the INSUFFICIENT check runs
      Then the check status is FAIL
      And a finding is produced for "users.feature" with check_type "INSUFFICIENT"
      And the finding detail is "users.feature Feature description shares no keywords with its BID scenarios"

    Scenario: A subspec has no BIDs — keyword overlap is not checked
      Given "users.feature" has a Feature description with 15 words
      And "users.feature" references no BIDs
      When the INSUFFICIENT check runs
      Then no keyword-overlap finding is produced for "users.feature"
```

Keyword extraction: For each BID, find the scenario tagged with `@{bid}` in the spec directory. Collect the text of all Given/When/Then/And/But steps in that scenario. Split into individual words (lowercased). Compare against words in the subspec Feature description (case-insensitive).

### 5. PARTIAL — SKIP

Deferred (J-v: requires semantic coverage analysis). Returns `status: SKIP`.

## Aggregation

The inspection runs checks 1–5 in order. Overall status is PASS when all active checks pass.

## Output Path

`.haileris/features/{feature_id}/layout-inspection.yaml`

## Edge Cases

- **No subspecs:** All primary spec BIDs are MISSING. DUPLICATED and INSUFFICIENT produce no findings.
- **Subspec with no BIDs:** The subspec contributes nothing to `subspec_bids`. It will not cause HALLUCINATED findings but may indicate a malformed subspec.
- **No primary spec:** `primary_bids` is empty. HALLUCINATED catches any BIDs in subspecs. MISSING produces no findings.
- **BID in Feature keyword line vs. scenario tags:** Only BIDs found as `@BID-NNN` scenario tags are extracted. BIDs embedded in Feature descriptions or step text are not captured.
