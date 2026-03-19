# Realize Inspection

Validates the Realize map after all subspecs complete. Source: [realize.md](../stages/realize.md) (Realize Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | YAML per [realize-map.md](../artifacts/realize-map.md) |
| Source files | Referenced by realize-map derivations | Source code files |

### Realize Map Structure

```yaml
feature_id: "{feature_id}"
subspecs_completed: 3
subspecs_total: 3
bids:
  BID-001:
    derivations:
      - src/module#MyClass.my_method
    subspec: "users.feature"
  BID-002:
    derivations:
      - src/module#function_name
    subspec: "auth.feature"
```

### Derivation Format

- Class method: `src/module#ClassName.method_name`
- Module-level function: `src/module#function_name`

The `#` separator delimits the file path from the derivation name.

### Entity Resolution

Split derivation at `#`, verify file exists, then search the file text for the top-level entity name (the part before any `.`). This is a grep-level check, not full AST resolution. It catches missing files and renamed entities but does not validate member access (e.g., `ClassName.method_name` only checks that `ClassName` appears in the file, not that `method_name` exists on it). Full member validation requires AST tooling (deferred to Tier 2 — Realize Scope check).

## Behavior

```gherkin
Feature: Realize Inspection
  Validates the realize-map BID-to-derivation mapping.

  Background:
    Given the spec files are in "tests/features/"
    And the realize map is at ".haileris/features/{feature_id}/realize-map.yaml"

  Rule: Completeness — every spec BID must have at least one derivation in the realize-map

    Scenario: All spec BIDs have derivations in the realize map
      Given the spec contains BIDs "BID-001, BID-002"
      And the realize map contains entries for "BID-001, BID-002"
      When the Completeness check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A spec BID has no derivation in the realize map
      Given the spec contains BIDs "BID-001, BID-002"
      And the realize map contains entries for "BID-001"
      When the Completeness check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "MISSING"
      And the finding detail is "BID-002 has no derivation in realize-map"

    Scenario: Multiple missing BIDs are reported in sorted order
      Given the spec contains BIDs "BID-001, BID-002, BID-003"
      And the realize map contains entries for "BID-002"
      When the Completeness check runs
      Then the check status is FAIL
      And findings are produced for "BID-001, BID-003" with check_type "MISSING"
      And findings are reported in sorted BID order

  Rule: Broken Refs — every derivation must resolve to an existing source entity

    Scenario: All derivations resolve to existing files and entities
      Given the realize map maps "BID-001" to derivation "src/module#MyClass"
      And the file "src/module" exists
      And "MyClass" appears in "src/module"
      When the Broken Refs check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A derivation has invalid format (missing #)
      Given the realize map maps "BID-001" to derivation "src/module.MyClass"
      When the Broken Refs check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "BROKEN_REF"
      And the finding detail contains "invalid format (missing #)"

    Scenario: A derivation file does not exist
      Given the realize map maps "BID-001" to derivation "src/missing#MyClass"
      And the file "src/missing" does not exist
      When the Broken Refs check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "BROKEN_REF"
      And the finding detail contains "derivation file not found: src/missing"

    Scenario: A derivation entity is not found in the file
      Given the realize map maps "BID-001" to derivation "src/module#MyClass"
      And the file "src/module" exists
      And "MyClass" does not appear in "src/module"
      When the Broken Refs check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "BROKEN_REF"
      And the finding detail contains "entity 'MyClass' not found in src/module"

    Scenario: A derivation with dot notation checks only the top-level entity
      Given the realize map maps "BID-001" to derivation "src/module#MyClass.my_method"
      And the file "src/module" exists
      And "MyClass" appears in "src/module"
      When the Broken Refs check runs
      Then the check status is PASS
```

### 3. Scope — SKIP

Deferred (M-c: requires language-specific AST tooling to discover all derivations in source files and compare against the realize-map). Returns `status: SKIP`. See [realize-scope.md](realize-scope.md) for the Tier 2 spec.

## Aggregation

The inspection runs checks 1–3 in order. If the realize-map is missing or invalid, the inspection fails immediately. Overall status is PASS when all active checks pass.

## Output Path

`.haileris/features/{feature_id}/realize-inspection.yaml`

## Edge Cases

- **Derivation with nested member access:** `src/module#Class.SubClass.method` — `entity_name` is `Class`. Only the top-level entity is checked. Nested member validation is deferred to the Scope check.
- **File path without extension:** Implementations should append the appropriate source file extension.
- **Entity name appears in comment/string:** The grep-level check does not distinguish entity name occurrences in code vs. comments vs. strings. This is a known false-negative risk (entity renamed in code but still referenced in a comment). Acceptable for Tier 1; full AST resolution in Tier 2.
- **Empty derivations list:** A BID with `derivations: []` is caught by Completeness (the BID exists in the map but has no derivations, which is equivalent to having the BID key without meaningful content). Implementations should treat an empty derivations list as equivalent to the BID being absent from the map for Completeness purposes, or flag it separately as a structural issue.
