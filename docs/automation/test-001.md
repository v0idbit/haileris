# TEST-001: BID Coverage Gate

Verifies every spec BID has at least one test function mapped in the etch-map. Source: [etch.md](../stages/etch.md) (step 3).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |

## Behavior

```gherkin
Feature: TEST-001 BID Coverage Gate
  Verifies every spec BID has at least one test function mapped in the etch-map
  with a non-empty tests list.

  Rule: BID coverage — every spec BID must have a mapped test in etch-map

    Scenario: All spec BIDs have etch-map entries with non-empty tests lists
      Given the spec contains BIDs "BID-001, BID-002"
      And the etch map contains entries for "BID-001, BID-002"
      And each entry has a non-empty tests list
      When the BID coverage check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: The etch-map is missing or invalid
      Given the etch-map file does not exist or is invalid YAML
      When the BID coverage check runs
      Then the check status is FAIL
      And a finding is produced with detail "etch-map.yaml not found or invalid"

    Scenario: A spec BID has no entry in the etch map
      Given the spec contains BIDs "BID-001, BID-002"
      And the etch map contains entries for "BID-001"
      When the BID coverage check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "MISSING"
      And the finding detail is "BID-002 has no test function in etch-map"

    Scenario: A spec BID has an entry with an empty tests list
      Given the spec contains BIDs "BID-001, BID-002"
      And the etch map contains entries for "BID-001, BID-002"
      And the entry for "BID-002" has an empty tests list
      When the BID coverage check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "MISSING"
      And the finding detail is "BID-002 is in etch-map but has an empty tests list"

    Scenario: Multiple missing BIDs are reported in sorted order
      Given the spec contains BIDs "BID-001, BID-002, BID-003"
      And the etch map contains entries for "BID-002"
      When the BID coverage check runs
      Then the check status is FAIL
      And findings are produced for "BID-001, BID-003" with check_type "MISSING"
      And findings are reported in sorted BID order

    Scenario: The spec has no BIDs
      Given the spec contains no BIDs
      When the BID coverage check runs
      Then the check status is PASS
      And no findings are produced
```

## Relationship to Etch Inspection

TEST-001 overlaps with the etch inspection's MISSING check. The distinction:

- **TEST-001** runs *during* Etch (step 3) as a gate before proceeding to RED state confirmation. It is a go/no-go signal: if any BID lacks a test, Etch must add the missing tests before continuing.
- **Etch Inspection MISSING** runs *after* Etch completes (step 5) as part of the full inspection report that feeds the Traceability Gate.

Both use the same BID set comparison. An implementation may share the underlying logic.

## Output

TEST-001 does not write a standalone inspection artifact. Its result determines whether Etch proceeds to TEST-002 (RED state confirmation). Implementations should emit the result to stdout and use exit codes (0 = PASS, 1 = FAIL) for gate enforcement.

## Edge Cases

- **Empty spec directory:** `spec_bids` is empty. TEST-001 passes vacuously (no BIDs to cover).
- **BID with empty tests list vs. absent BID:** Both are MISSING findings. An empty `tests: []` entry is functionally equivalent to the BID being absent — neither provides test coverage.
- **Extra BIDs in etch-map:** BIDs in the map that are not in the spec are not flagged by TEST-001. That is the etch inspection's HALLUCINATED check.
