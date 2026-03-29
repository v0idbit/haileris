# Etch Inspection

Validates `etch-map.yaml` BID → test function mapping. Source: [etch.md](../stages/etch.md) (Etch Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/{feature_id}/*.feature` | Gherkin with `@BID-NNN` tags |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |
| Test source files | Referenced by etch-map entries | Source code files |

### Etch Map Structure

```yaml
bids:
  BID-001:
    tests:
      - tests/unit/test_feature#test_create_user
      - tests/unit/test_feature#test_create_user_duplicate
  BID-002:
    tests:
      - tests/integration/test_workflow#test_full_pipeline
```

The `#` separator delimits the file path from the function name. Parameterization suffixes (e.g., `[foo]`) may follow the function name.

### Map BID Extraction

Map BIDs are the set of keys in `etch_map.bids` matching regex `^BID-\d+$`.

### Non-trivial Lines

A **non-trivial line** in a function body is one that is not blank, not a comment, not a docstring, and not a decorator/annotation. The implementation determines how to identify function boundaries and count these lines based on the target language.

## Behavior

```gherkin
Feature: Etch Inspection
  Validates etch-map.yaml BID-to-test-function mapping across 5 dimensions.

  Background:
    Given the spec files are in "tests/features/{feature_id}/"
    And the etch map is at ".haileris/features/{feature_id}/etch-map.yaml"

  Rule: MISSING — every spec BID must have an etch-map entry

    Scenario: All spec BIDs have etch-map entries
      Given the spec contains BIDs "BID-001, BID-002"
      And the etch map contains entries for "BID-001, BID-002"
      When the MISSING check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A spec BID is absent from the etch map
      Given the spec contains BIDs "BID-001, BID-002"
      And the etch map contains entries for "BID-001"
      When the MISSING check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "MISSING"
      And the finding detail is "BID-002 has no entry in etch-map"

    Scenario: Multiple missing BIDs are reported in sorted order
      Given the spec contains BIDs "BID-001, BID-002, BID-003"
      And the etch map contains entries for "BID-002"
      When the MISSING check runs
      Then the check status is FAIL
      And findings are produced for "BID-001, BID-003" with check_type "MISSING"
      And findings are reported in sorted BID order

  Rule: HALLUCINATED — every etch-map BID must have a corresponding spec entry

    Scenario: All etch-map BIDs exist in the spec
      Given the spec contains BIDs "BID-001, BID-002"
      And the etch map contains entries for "BID-001, BID-002"
      When the HALLUCINATED check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: An etch-map BID has no corresponding spec entry
      Given the spec contains BIDs "BID-001"
      And the etch map contains entries for "BID-001, BID-002"
      When the HALLUCINATED check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "HALLUCINATED"
      And the finding detail is "BID-002 is in etch-map but not in spec"

  Rule: INSUFFICIENT — every mapped test function must have at least 3 non-trivial body lines

    Scenario: A test function meets the line threshold
      Given the etch map maps "BID-001" to "tests/unit/test_feature#test_create_user"
      And the function "test_create_user" has 5 non-trivial body lines
      When the INSUFFICIENT check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A test function has fewer than 3 non-trivial body lines
      Given the etch map maps "BID-001" to "tests/unit/test_feature#test_create_user"
      And the function "test_create_user" has 2 non-trivial body lines
      When the INSUFFICIENT check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "INSUFFICIENT"
      And the finding detail contains "test function 'test_create_user' in tests/unit/test_feature has 2 body line(s) (need ≥3)"

    Scenario: A test file does not exist
      Given the etch map maps "BID-001" to "tests/unit/missing_file#test_func"
      And the file "tests/unit/missing_file" does not exist
      When the INSUFFICIENT check runs
      Then no finding is produced for "BID-001"

    Scenario: A test function is not found in its file
      Given the etch map maps "BID-001" to "tests/unit/test_feature#nonexistent_func"
      And the file "tests/unit/test_feature" exists
      And the function "nonexistent_func" is not defined in the file
      When the INSUFFICIENT check runs
      Then no finding is produced for "BID-001"

    Scenario: Parameterization suffixes are stripped before function lookup
      Given the etch map maps "BID-001" to "tests/unit/test_feature#test_func[case_a]"
      And the function "test_func" has 2 non-trivial body lines
      When the INSUFFICIENT check runs
      Then a finding is produced for "BID-001" with check_type "INSUFFICIENT"

    Scenario: A test reference has no "#" separator
      Given the etch map maps "BID-001" to "tests/unit/test_feature"
      When the INSUFFICIENT check runs
      Then no finding is produced for "BID-001"
```

### 4. DUPLICATED — Agent-Evaluated

No mechanical specification. The pipeline agent evaluates whether two test functions mapped to the same BID are substantially similar. The inspection records `status: SKIP` for this check.

### 5. PARTIAL — Agent-Evaluated

No mechanical specification. The pipeline agent evaluates whether a BID's mapped tests leave Gherkin Then clauses uncovered. The inspection records `status: SKIP` for this check.

## Aggregation

The inspection runs checks 1–5 in order. If the etch-map is missing or invalid, the inspection fails immediately. Overall status is PASS when all mechanically verified checks pass.

## Output Path

`.haileris/features/{feature_id}/etch-inspection.yaml`

## Edge Cases

- **Empty tests list:** A BID with `tests: []` is structurally valid but has no test coverage. This is caught by [TEST-001](test-001.md), not by INSUFFICIENT (which only examines functions that exist).
- **Parameterized tests:** `test_func[param_value]` — strip the `[...]` suffix before looking up the function definition. The parameterization is a test framework convention; the function body is the same for all parameter values.
- **File path without extension:** The etch-map may use extensionless paths (e.g., `tests/unit/test_feature`). Implementations should append the appropriate source file extension for the project's language.
- **Missing file:** If the test file does not exist, INSUFFICIENT skips it. A missing file is a structural issue in the etch-map, not an insufficiency of the function body.
- **Function not found in file:** If the named function does not exist in the file, INSUFFICIENT skips it. This is also a structural issue.
