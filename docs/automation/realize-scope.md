# Realize Scope (AST)

Discovers all derivations in source files via static analysis and compares against the realize-map. Unmapped derivations indicate scope creep — code that exists without BID justification. Source: [realize.md](../stages/realize.md) (Realize Inspection: Scope check).

## Constraint

**Condition:** AST tooling is available for the target language.

The check requires a language-specific AST parser capable of enumerating named callables and types in source files (e.g., `ast` module for Python, tree-sitter for multi-language, TypeScript compiler API for TS/JS).

When AST tooling is unavailable:

```
status: SKIP
detail: "AST tooling not available for target language; mechanical scope check unavailable"
```

For mainstream languages (Python, JavaScript, TypeScript, Java, Go, Rust, C#), reliable AST parsers exist and this check is effectively fully mechanical.

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | YAML per [realize-map.md](../artifacts/realize-map.md) |
| Source files | Directories referenced by realize-map derivations | Source code files |

### Realize Map Derivation Format

```yaml
bids:
  BID-001:
    derivations:
      - src/module#MyClass.my_method
      - src/module#helper_function
```

The `#` separator delimits the file path from the derivation name. Class methods use dot notation: `ClassName.method_name`.

### Derivation Discovery

A "derivation" is a named callable or type definition: functions, methods, classes, structs, interfaces, or enums. The AST parser enumerates these from source files in directories referenced by the realize-map. Source directories are extracted from the file path portion (before `#`) of each derivation reference.

Derivation references use the format `file_key#entity_name`, where `file_key` is the file path without extension and `entity_name` uses dot notation for class members. Both AST-discovered and mapped derivations must use the same normalization (no extension, forward slashes, dot notation).

## Behavior

```gherkin
Feature: Realize Scope Check
  Discovers all derivations via AST analysis and compares against the realize-map
  to detect scope creep.

  Rule: Constraint gate — AST tooling must be available

    Scenario: AST tooling is unavailable
      Given AST tooling is not available for the target language
      When the scope check runs
      Then the check status is SKIP
      And the detail is "AST tooling not available for target language; mechanical scope check unavailable"

    Scenario: Realize map is missing or invalid
      Given "realize-map.yaml" does not exist or is invalid
      When the scope check runs
      Then the check status is FAIL
      And the detail is "realize-map.yaml not found or invalid"

  Rule: Scope check — every discovered derivation must be mapped to a BID

    Scenario: All discovered derivations are mapped
      Given the realize map contains derivations "src/module#func_a, src/module#func_b"
      And AST discovery in "src/module" finds derivations "func_a, func_b"
      When the scope check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A source derivation has no BID mapping
      Given the realize map contains derivations "src/module#func_a"
      And AST discovery in "src/module" finds derivations "func_a, func_b"
      When the scope check runs
      Then the check status is FAIL
      And a finding is produced with check_type "SCOPE_CREEP"
      And the finding detail contains "src/module#func_b"
      And the finding detail contains "found in source but not mapped to any BID"

    Scenario: Multiple unmapped derivations are reported in sorted order
      Given the realize map contains derivations "src/module#func_b"
      And AST discovery finds derivations "func_a, func_b, func_c" in "src/module"
      When the scope check runs
      Then the check status is FAIL
      And findings are produced for "src/module#func_a" and "src/module#func_c" with check_type "SCOPE_CREEP"

    Scenario: Class methods are discovered with dot notation
      Given the realize map maps "BID-001" to derivation "src/module#MyClass.my_method"
      And AST discovery in "src/module" finds "MyClass" and "MyClass.my_method"
      When the scope check runs
      Then "src/module#MyClass" and "src/module#MyClass.my_method" are both considered
      And only unmapped derivations produce findings

    Scenario: A source directory does not exist
      Given the realize map references derivations in "src/missing/"
      And "src/missing/" does not exist
      When the scope check runs
      Then no derivations are discovered for that directory

    Scenario: Empty realize-map — vacuous pass
      Given the realize map has no BID entries
      When the scope check runs
      Then the check status is PASS
      And no findings are produced
```

## Integration with Realize Inspection

This check replaces the SKIP placeholder in [realize-inspection.md](realize-inspection.md) (check 3: Scope). When AST tooling is available, the realize inspection runs Completeness, Broken Refs, and Scope in order.

## Output

Findings are part of the realize inspection result, written to:

`.haileris/features/{feature_id}/realize-inspection.yaml`

Each unmapped derivation produces a Finding:

```
Finding:
  bid          — "N/A" (unmapped derivations have no BID by definition)
  check_type   — "SCOPE_CREEP"
  detail       — derivation reference and source location
```

## Scope Creep Detection (Inspect Review)

The realize-scope findings directly feed the Inspect.Review complexity and scope check. Unmapped derivations discovered here are surfaced as HIGH-severity scope creep findings in the Inspect verify report. This is a wiring step: the scope creep component of Inspect.Review consumes existing realize inspection output.

## Edge Cases

- **Generated code:** Code generators, build tool outputs, and vendored dependencies may produce derivations that should not be mapped. Implementations should support an exclusion list (e.g., `realize-scope-exclude.yaml`) of directory patterns or file globs to skip during AST discovery.
- **Metaprogramming and dynamic definitions:** Derivations created at runtime (e.g., Python `type()`, Ruby `define_method`, JavaScript `eval`) are invisible to static AST analysis. This is an accepted limitation of the M-c boundary. The constraint section documents this explicitly.
- **Test files in source directories:** If test files coexist with source files in the same directory, their test functions will appear as AST-discovered derivations. Implementations should exclude files matching test naming conventions (e.g., `test_*.py`, `*.test.js`) or directories named `tests/`, `__tests__/`.
- **Nested classes and inner functions:** `discover_derivations` enumerates class methods via dot notation. Deeply nested structures (inner classes, closures with names) should use the same dot-delimited convention: `file#Outer.Inner.method`.
- **Derivation normalization:** The set difference requires consistent formatting. Both AST-discovered and mapped derivations must use the same conventions for file paths (no extension, forward slashes) and entity names (dot notation for members).
- **Empty realize-map:** If `realize-map.yaml` has no BID entries, no AST scanning occurs. The check passes vacuously (no unmapped derivations because nothing was scanned). The Completeness check (Tier 1) handles the missing-BID concern.
