# ANLZ-007: Data Contract Compliance

Validates that test function signatures use named data contract types for collections and compound types. Bare generic annotations are prohibited; scalar primitives are allowed. Source: [etch.md](../stages/etch.md) (Data Contract Compliance section).

**Tier:** M-c (mechanical with constraints). Requires language-specific type annotation parsing.

## Constraint

**Condition:** Type annotation parsing is available for the target language.

Per-language bare generic patterns:

| Language | Bare generic patterns |
|----------|----------------------|
| Python | `dict`, `list`, `tuple`, `set`, `Any`, `object`, `Dict`, `List`, `Tuple`, `Set`, `Dict[...]`, `List[...]`, `Tuple[...]`, `Set[...]` |
| TypeScript | `object`, `any`, `Record<...>`, `Array<...>`, `Map<...>`, `Set<...>`, `{}` |
| Java | `Object`, `Map<...>`, `List<...>`, `Set<...>`, `Collection<...>` |
| Go | `map[...]...`, `[]...` (slice), `interface{}`, `any` |

When type annotation parsing is unavailable for the target language:

```
status: SKIP
detail: "Type annotation parsing unavailable for target language; data contract compliance check skipped"
```

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |
| Test source files | Referenced by etch-map entries | Source code files |
| Language config | Implementation-defined | Bare generic pattern table + type annotation parser |

## Behavior

```gherkin
Feature: ANLZ-007 Data Contract Compliance
  Validates that test function signatures use named data contract types
  instead of bare generic annotations.

  Background:
    Given the etch map is loaded
    And type annotation parsing is available for the target language

  Rule: Constraint gate — type annotation parsing must be available

    Scenario: Type annotation parsing is unavailable
      Given no type annotation parser exists for the target language
      When the data contract compliance check runs
      Then the check status is SKIP
      And the detail is "Type annotation parsing unavailable for target language; data contract compliance check skipped"

  Rule: Bare generics in parameters are prohibited

    Scenario: A parameter uses a bare generic type
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" has a parameter annotated as "dict"
      When the data contract compliance check runs
      Then the check status is FAIL
      And a finding is produced with check_type "BARE_GENERIC"
      And the finding detail contains "test_create_user parameter uses bare generic 'dict'"

    Scenario: A parameter uses a named contract type
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" has a parameter annotated as "UserRecord"
      When the data contract compliance check runs
      Then no finding is produced for "BID-001"

  Rule: Bare generics in return types are prohibited

    Scenario: A return type uses a bare generic
      Given the etch map maps "BID-001" to "tests/test_feature#test_list_users"
      And "test_list_users" has a return type annotated as "list"
      When the data contract compliance check runs
      Then the check status is FAIL
      And a finding is produced with check_type "BARE_GENERIC"
      And the finding detail contains "test_list_users return type uses bare generic 'list'"

  Rule: Scalar primitives are allowed

    Scenario: A parameter uses a scalar primitive
      Given the etch map maps "BID-001" to "tests/test_feature#test_get_name"
      And "test_get_name" has a parameter annotated as "str"
      When the data contract compliance check runs
      Then no finding is produced for "BID-001"

    Scenario: A return type uses a scalar primitive
      Given the etch map maps "BID-001" to "tests/test_feature#test_get_count"
      And "test_get_count" has a return type annotated as "int"
      When the data contract compliance check runs
      Then no finding is produced for "BID-001"

  Rule: Named types are allowed

    Scenario: A parameter uses a stdlib named type
      Given the etch map maps "BID-001" to "tests/test_feature#test_read_file"
      And "test_read_file" has a parameter annotated as "Path"
      When the data contract compliance check runs
      Then no finding is produced for "BID-001"

  Rule: All functions are checked regardless of visibility

    Scenario: A private helper function uses a bare generic
      Given the etch map maps "BID-001" to "tests/test_feature#_build_payload"
      And "_build_payload" has a parameter annotated as "dict"
      When the data contract compliance check runs
      Then the check status is FAIL
      And a finding is produced with check_type "BARE_GENERIC"

  Rule: Nested generics with bare outer container are prohibited

    Scenario: A parameter uses a bare generic wrapping a named type
      Given the etch map maps "BID-001" to "tests/test_feature#test_list_users"
      And "test_list_users" has a parameter annotated as "list[UserRecord]"
      When the data contract compliance check runs
      Then the check status is FAIL
      And a finding is produced with check_type "BARE_GENERIC"
      And the finding detail contains "test_list_users parameter uses bare generic 'list[UserRecord]'"

  Rule: Unannotated parameters are not bare generics

    Scenario: A parameter has no type annotation
      Given the etch map maps "BID-001" to "tests/test_feature#test_create_user"
      And "test_create_user" has a parameter with no type annotation
      When the data contract compliance check runs
      Then no finding is produced for "BID-001"

    Scenario: No parameters have type annotations
      Given the etch map maps "BID-001" to "tests/test_feature#test_simple"
      And "test_simple" has no type annotations at all
      When the data contract compliance check runs
      Then no finding is produced for "BID-001"

  Rule: Optional wrapping a bare generic is prohibited

    Scenario: A parameter uses Optional wrapping a bare generic
      Given the etch map maps "BID-001" to "tests/test_feature#test_update_user"
      And "test_update_user" has a parameter annotated as "Optional[dict]"
      When the data contract compliance check runs
      Then the check status is FAIL
      And a finding is produced with check_type "BARE_GENERIC"
      And the finding detail contains "test_update_user parameter uses bare generic 'Optional[dict]'"
```

## Output

Each finding includes:

```
Finding:
  bid          — BID from etch-map
  check_type   — "BARE_GENERIC"
  detail       — function name, file path, and the offending type annotation
```

ANLZ-007 does not write a standalone inspection artifact. Its findings are part of the Etch process output (step 6).

## Edge Cases

- **Unannotated parameters:** PASS — the absence of a type annotation is not a bare generic. This check targets explicit annotations only.
- **Nested generics:** `list[UserRecord]` fails — the outer `list` is a bare generic container. The fix is a named collection type (e.g., `UserList`).
- **Optional wrapping a bare generic:** `Optional[dict]` fails — the inner `dict` is bare. The fix is `Optional[UserConfig]` or equivalent.
- **Stdlib named types:** `Path`, `datetime`, `Decimal`, etc. are named types and pass. They are not generic containers.
- **No annotations at all:** PASS — a function with no type annotations produces no findings.
- **Language without type system:** SKIP — languages that lack type annotation syntax (e.g., plain JavaScript without JSDoc) trigger the constraint gate.
- **Parameterized test functions:** Parameterization suffixes (e.g., `[case_a]`) are stripped before function lookup, consistent with other etch-map lookups.
