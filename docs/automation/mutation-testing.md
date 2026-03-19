# Mutation Testing Engine

BID-targeted mutation generation, execution, and kill rate reporting. Each mutation targets an observable behavioral assertion from a BID's Gherkin Then/And steps. Surviving mutations indicate untested behavioral gaps. Source: [inspect.md](../stages/inspect.md) (Inspect.Review: Mutation testing).

## Constraint

**Condition:** Standard mutation operators are available for the target language, and derivations are traceable via realize-map.

The engine requires:
1. A mutation operator set applicable to the target language's syntax (AST manipulation or source-level text transformation)
2. A test runner that can execute a subset of tests and report pass/fail per test
3. A realize-map mapping BIDs to derivation paths
4. An etch-map mapping BIDs to test function paths

When any of these are unavailable:

```
status: SKIP
detail: "Mutation testing prerequisites not met: {missing_component}; mutation testing unavailable"
```

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | YAML per [realize-map.md](../artifacts/realize-map.md) |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags and Then/And steps |
| Source files | Referenced by realize-map derivations | Source code files |
| Test files | Referenced by etch-map entries | Test source files |

## Mutation Operators

Five categories of behavioral mutations. Each mutates an expression that affects an observable behavioral assertion.

| Category | Examples |
|----------|---------|
| **Boundary Conditions** | `<` ↔ `<=`, `>` ↔ `>=`, `N` → `N±1`, inclusive ↔ exclusive range |
| **Comparison Operators** | `==` ↔ `!=`, `<` ↔ `>`, `<=` ↔ `>=`, `===` ↔ `!==` |
| **Argument Order** | Swap adjacent arguments in calls: `f(a, b)` → `f(b, a)` (compatible types only) |
| **Branch Logic** | Negate condition, remove if/else branch, `&&` ↔ `\|\|`, remove conditional block |
| **Return Values** | `true` ↔ `false`, return default value, return empty collection, negate numeric return |

### Behavioral-Only Filter

Each mutation targets an expression affecting an observable behavioral assertion from the BID's Gherkin Then/And steps. Structural-only lines are excluded: docstrings, comments, string literals not used in assertions, variable/parameter renames, type annotations, decorators, import statements, whitespace/formatting.

## Behavior

```gherkin
Feature: Mutation Testing Engine
  BID-targeted mutation generation, execution, and kill rate reporting.

  Rule: Constraint gate — all mutation testing prerequisites must be met

    Scenario: Realize map is missing
      Given "realize-map.yaml" does not exist
      When mutation testing runs
      Then the check status is SKIP
      And the detail contains "missing realize-map"

    Scenario: Etch map is missing
      Given "etch-map.yaml" does not exist
      When mutation testing runs
      Then the check status is SKIP
      And the detail contains "missing realize-map or etch-map"

    Scenario: Mutation operators are unavailable for the target language
      Given mutation operators are not available for the target language
      When mutation testing runs
      Then the check status is SKIP
      And the detail contains "Mutation testing prerequisites not met"

  Rule: Mutation generation — only behavioral mutations are produced

    Scenario: A derivation line matches a mutation operator
      Given "BID-001" maps to derivation "src/module#my_func"
      And "my_func" contains the line "if count < threshold:"
      When mutations are generated for "BID-001"
      Then a Boundary Condition mutation is produced: "if count <= threshold:"
      And a Comparison Operator mutation is produced: "if count > threshold:"

    Scenario: A structural-only line produces no mutations
      Given "BID-001" maps to derivation "src/module#my_func"
      And "my_func" contains only a comment line "# setup complete"
      When mutations are generated for that line
      Then no mutations are produced

    Scenario: A derivation file does not exist — skipped
      Given "BID-001" maps to derivation "src/missing#my_func"
      And the file "src/missing" does not exist
      When mutations are generated for "BID-001"
      Then no mutations are produced for that derivation

    Scenario: A BID has no derivations in the realize-map — skipped
      Given "BID-001" has no entry in the realize map
      When mutation testing considers "BID-001"
      Then "BID-001" is skipped

    Scenario: A BID has no tests in the etch-map — skipped
      Given "BID-001" has no entry in the etch map
      When mutation testing considers "BID-001"
      Then "BID-001" is skipped

  Rule: Mutation execution — each mutation is applied, tested, and reverted

    Scenario: A test fails after mutation — mutation is killed
      Given a mutation is applied to "src/module#my_func"
      And the BID's tests are executed
      And at least one test fails
      Then the mutation status is "KILLED"
      And the mutation is reverted

    Scenario: All tests pass after mutation — mutation survived
      Given a mutation is applied to "src/module#my_func"
      And the BID's tests are executed
      And all tests pass
      Then the mutation status is "SURVIVED"
      And the mutation is reverted

    Scenario: A mutation causes a timeout — treated as killed
      Given a mutation is applied to "src/module#my_func"
      And the BID's tests exceed the per-mutation timeout
      Then the mutation status is "KILLED"
      And the mutation is reverted

    Scenario: A BID has no tests — mutations cannot be evaluated
      Given "BID-001" has an empty tests list in the etch map
      And mutations were generated for "BID-001"
      Then no mutation results are produced for "BID-001"

  Rule: Reporting — surviving mutations produce findings with kill rate

    Scenario: All mutations are killed — no findings
      Given "BID-001" has 5 mutations
      And all 5 mutations are killed
      When mutation results are reported
      Then no findings are produced for "BID-001"

    Scenario: A mutation survives — a finding is produced
      Given "BID-001" has 5 mutations
      And 4 are killed and 1 survives
      When mutation results are reported
      Then a finding is produced for "BID-001" with check_type "SURVIVING_MUTATION"
      And the finding detail contains the mutation operator and location
      And the finding detail contains "Kill rate for BID-001"

    Scenario: Multiple mutations survive — one finding per surviving mutation
      Given "BID-001" has 5 mutations
      And 3 are killed and 2 survive
      When mutation results are reported
      Then 2 findings are produced for "BID-001" with check_type "SURVIVING_MUTATION"

    Scenario: No BIDs have applicable mutations
      Given no BIDs produce any mutation sites
      When mutation testing runs
      Then the check status is PASS
      And no findings are produced
```

## Output

Mutation testing results are part of the Inspect.Review output. Each surviving mutation produces a Medium finding:

```
Finding:
  bid          — BID from realize-map
  check_type   — "SURVIVING_MUTATION"
  detail       — mutation operator, location, original/mutated code, kill rate
```

The gap description for surviving mutations (explaining *what behavioral gap* the mutation reveals) is out of scope for this spec — it requires judgment (J-class). This spec reports the surviving mutation and the passing test; a human or LLM reviewer provides the behavioral interpretation.

## Edge Cases

- **Equivalent mutations:** Some mutations produce functionally equivalent code (e.g., reordering commutative operations). These survive all tests but are not true gaps. Implementations may maintain an equivalent-mutation allowlist per operator, but this is optional — false positives (flagging equivalent mutations) are safe and can be reviewed.
- **Infinite loops and timeouts:** A mutation may cause an infinite loop or excessive computation. Implementations must set a per-mutation timeout. A timed-out mutation is treated as KILLED (the behavioral change caused an observable effect, even if it's a hang rather than a test failure).
- **Mutation in shared code:** A derivation mapped to multiple BIDs (shared utility) should be mutated once, with tests from all BIDs that reference it. The kill rate is calculated per BID (each BID's tests are run independently against the mutation).
- **No mutation sites:** If a derivation contains only structural lines (imports, docstrings, type annotations), mutation generation is skipped. This is correct behavior — all lines are structural (imports, docstrings, type annotations).
- **Test infrastructure failures:** If the test runner itself fails (not a test failure, but a runner crash), the mutation result is inconclusive. Log a warning and exclude the mutation from kill rate calculation.
- **Large derivation count:** For BIDs with many derivations, mutation count can grow combinatorially. Implementations may cap mutations per BID (e.g., 100 mutations) and sample across derivations to maintain reasonable execution time. Report the cap in the output detail.
- **Mutation operator compatibility:** Not all operators apply to all languages. Argument order swapping requires positional argument syntax; strict equality operators exist only in JavaScript/TypeScript. The operator set should be filtered to the target language's applicable operators.
