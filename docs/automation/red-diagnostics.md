# RED Diagnostics: Default-Value and Tautological Assertion Detection

Two related Etch RED state diagnostics that identify tests passing before production code exists. Source: [etch.md](../stages/etch.md) (RED State Confirmation table).

**Default-value detection** flags assertions whose expected values match language defaults — the assertion passes because the unimplemented callable returns a default, not because it computes the correct result.

**Tautological assertion detection** flags assertions that hold true independent of production code execution — the assertion tests Arrange data or constants rather than Act-section output.

## Constraints

### Default-Value Detection

**Condition:** A language default value table is available for the target language.

The table enumerates values that unimplemented or stub callables return by default:

| Language | Default values |
|----------|---------------|
| Python | `None`, `0`, `0.0`, `""`, `[]`, `{}`, `set()`, `()`, `False` |
| JavaScript | `undefined`, `null`, `0`, `NaN`, `""`, `[]`, `{}`, `false` |
| TypeScript | Same as JavaScript |
| Java | `null`, `0`, `0.0`, `0L`, `false`, `""` |
| Go | `nil`, `0`, `0.0`, `""`, `false` (zero values per type) |

When no default value table exists for the target language:

```
status: SKIP
detail: "No default value table available for target language; mechanical default-value detection unavailable"
```

### Tautological Assertion Detection

**Condition:** Test functions follow AAA (Arrange/Act/Assert) structure with identifiable section boundaries.

Section boundaries are identified by:
1. **Comment markers** — `# Arrange`, `// Arrange`, `# Act`, `// Act`, `# Assert`, `// Assert` (or language-appropriate comment syntax)
2. **Positional heuristic** — when markers are absent: initial assignments are Arrange, the first call to a production callable is Act, subsequent assertions are Assert

When AAA boundaries are indeterminate:

```
status: SKIP
detail: "AAA section boundaries not identifiable in test function; tautological assertion detection unavailable"
```

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |
| Test source files | Referenced by etch-map entries | Source code files |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | YAML (for domain path resolution) |
| Language config | Implementation-defined | Default value table + assertion patterns |

### Test Function Analysis

Both diagnostics iterate over BID → test function mappings in the etch-map. For each test reference, the implementation locates the named function in the source file (stripping parameterization suffixes like `[case_a]`), extracts its body lines, and identifies assertion statements. Assertion patterns are language-specific (e.g., `assert x == value` in Python, `expect(x).toBe(value)` in JS/TS, `assertEquals(value, x)` in Java).

### AAA Section Identification

The tautological detection requires segmenting test function body lines into Arrange, Act, and Assert sections. Comment markers are preferred; when absent, a positional heuristic identifies Arrange (initial assignments), Act (first production callable invocation), and Assert (assertion statements). If section boundaries are indeterminate, the function is skipped.

## Behavior

```gherkin
Feature: RED Diagnostics
  Detects default-value assertions and tautological assertions in test functions
  during Etch RED state confirmation.

  Rule: Default-value constraint gate — a language default value table must be available

    Scenario: No default value table is available
      Given no default value table exists for the target language
      When the default-value detection check runs
      Then the check status is SKIP
      And the detail is "No default value table available for target language; mechanical default-value detection unavailable"

  Rule: Default-value detection — assertions must expect values distinct from language defaults

    Scenario: An assertion expects a non-default value
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" contains an assertion expecting "Alice"
      When the default-value detection check runs
      Then no finding is produced for "BID-001"

    Scenario: An assertion expects a language default value
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" contains an assertion expecting "None"
      And "None" is in the default value table
      When the default-value detection check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "DEFAULT_VALUE_ASSERTION"
      And the finding detail contains "asserts expected value 'None' which is a language default"

    Scenario: An assertion expects an empty collection
      Given the etch map maps "BID-001" to "tests/test_feature#test_list_items"
      And "test_list_items" contains an assertion expecting "[]"
      And "[]" is in the default value table
      When the default-value detection check runs
      Then a finding is produced for "BID-001" with check_type "DEFAULT_VALUE_ASSERTION"

    Scenario: The test file does not exist — skipped
      Given the etch map maps "BID-001" to "tests/missing_file#test_func"
      And the file "tests/missing_file" does not exist
      When the default-value detection check runs
      Then no finding is produced for "BID-001"

    Scenario: The test function is not found in the file — skipped
      Given the etch map maps "BID-001" to "tests/test_feature#nonexistent_func"
      And the file "tests/test_feature" exists
      And "nonexistent_func" is not defined in the file
      When the default-value detection check runs
      Then no finding is produced for "BID-001"

    Scenario: Multiple assertions in one test function produce independent findings
      Given the etch map maps "BID-001" to "tests/test_feature#test_multi"
      And "test_multi" contains an assertion expecting "None" and another expecting "0"
      And both values are in the default value table
      When the default-value detection check runs
      Then two findings are produced for "BID-001" with check_type "DEFAULT_VALUE_ASSERTION"

  Rule: Tautological constraint gate — AAA section boundaries must be identifiable

    Scenario: AAA boundaries cannot be determined for a test function
      Given the etch map maps "BID-001" to "tests/test_feature#test_ambiguous"
      And "test_ambiguous" has no comment markers and ambiguous structure
      When the tautological assertion check runs for "BID-001"
      Then no finding is produced for "BID-001"

  Rule: Tautological detection — assertions must reference Act output, not only Arrange data

    Scenario: An assertion references a variable assigned in the Act section
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" has identifiable AAA sections
      And the Assert section references a variable assigned in the Act section
      When the tautological assertion check runs
      Then no finding is produced for "BID-001"

    Scenario: An assertion references only Arrange-section variables
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" has identifiable AAA sections
      And the Assert section references only variables assigned in the Arrange section
      When the tautological assertion check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "TAUTOLOGICAL_ASSERTION"
      And the finding detail contains "references only Arrange-section data, not Act output"

    Scenario: An assertion compares a value to itself
      Given the etch map maps "BID-001" to "tests/test_feature#test_identity"
      And "test_identity" contains an assertion where expected equals actual
      When the tautological assertion check runs
      Then a finding is produced for "BID-001" with check_type "TAUTOLOGICAL_ASSERTION"
      And the finding detail contains "compares a value to itself"

    Scenario: An assertion evaluates to true unconditionally
      Given the etch map maps "BID-001" to "tests/test_feature#test_trivial"
      And "test_trivial" contains "assert True"
      When the tautological assertion check runs
      Then a finding is produced for "BID-001" with check_type "TAUTOLOGICAL_ASSERTION"
      And the finding detail contains "evaluates to true unconditionally"

    Scenario: Parameterization suffix is stripped before function lookup
      Given the etch map maps "BID-001" to "tests/test_feature#test_func[case_a]"
      And the function "test_func" contains a tautological assertion
      When the tautological assertion check runs
      Then a finding is produced for "BID-001" with check_type "TAUTOLOGICAL_ASSERTION"
```

## Aggregation

Both diagnostics run independently and produce separate check results.

## Output

RED diagnostic findings are part of the Etch RED state confirmation output. Each finding tags the BID via etch-map lookup.

```
Finding:
  bid          — BID from etch-map
  check_type   — "DEFAULT_VALUE_ASSERTION" or "TAUTOLOGICAL_ASSERTION"
  detail       — test function, file, and specific issue description
```

These findings feed the RED correction workflow defined in [etch.md](../stages/etch.md): default-value assertions are corrected by strengthening to specific values derived from Gherkin; tautological assertions are rewritten to verify observable production code effects.

## Edge Cases

- **Assertion with computed default:** `assert result == len([])` evaluates to `assert result == 0`. The default-value check operates on the literal expression text, not the computed value. Implementations may optionally evaluate constant expressions to catch these, but this is not required.
- **Multiple assertions per test:** Each assertion is checked independently. A test function may produce multiple findings (one default-value and one tautological, for example).
- **Assertion in helper function:** If the test function delegates assertions to a helper (e.g., `self.assert_defaults(result)`), the helper's body is not analyzed. Only assertions directly in the test function body are checked. This is an accepted limitation.
- **Parameterized test expected values:** For parameterized tests (`test_func[param]`), the expected value may come from the parameter. If the parameter value is a default value, this is flagged. The parameterization suffix is stripped before function lookup, so the same function body is analyzed for all parameter values.
- **AAA section ambiguity:** When the positional heuristic fails (e.g., multiple production calls, assertions interleaved with assignments), the tautological check skips that function. This degrades gracefully rather than producing false results.
- **Language-specific assertion libraries:** Assertion pattern matching requires an extensible set of patterns. Each new assertion style (pytest, unittest, Jest, JUnit, testify, etc.) adds patterns but does not change the algorithm.
- **Negation assertions:** `assertIsNone(result)` explicitly asserts a default value. This should match `None` in the default value table. `assertIsNotNone(result)` is a positive assertion and passes the check.
