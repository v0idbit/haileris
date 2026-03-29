# ANLZ-005: Interface Contract Consistency

Fully mechanical consistency check. Validates that subspec `Requires:` and `Provides:` declarations form a consistent, acyclic interface graph. Source: [layout.md](../stages/layout.md) (ANLZ-005 section).

**Tier:** M (fully mechanical). Parsing and set operations only.

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Subspec files | `tests/features/{feature_id}/{deliverable}.feature` | Gherkin with `Requires:` and `Provides:` lines |

### Parsing Formats

**`Requires:` line:** Scan each subspec file for lines matching `Requires?:\s*(.+)`. Split the matched value on commas, trim whitespace. Each entry has format `{file}.feature -> {ContractName} ({description})`.

**`Provides:` line:** Scan each subspec file for lines matching `Provides?:\s*(.+)`. Split the matched value on commas, trim whitespace. Each entry has format `{ContractName} ({description})`.

## Behavior

```gherkin
Feature: ANLZ-005 Interface Contract Consistency
  Validates that subspec Requires: and Provides: declarations form
  a consistent, acyclic interface graph.

  Background:
    Given the spec directory is "tests/features/{feature_id}/"

  Rule: Every Requires ContractName must match a Provides ContractName

    Scenario: All Requires are satisfied by Provides
      Given subspec "auth.feature" Provides: "AuthToken (JWT session token)"
      And subspec "users.feature" Requires: "auth.feature -> AuthToken (JWT session token)"
      When the interface contract check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A Requires ContractName has no matching Provides
      Given subspec "users.feature" Requires: "auth.feature -> AuthToken (JWT session token)"
      And no subspec Provides: "AuthToken"
      When the interface contract check runs
      Then the check status is FAIL
      And a finding is produced with check_type "UNSATISFIED_REQUIRES"
      And the finding detail contains "users.feature requires AuthToken but no subspec provides it"

    Scenario: File reference in Requires names a different file than the one that Provides
      Given subspec "auth.feature" Provides: "AuthToken (JWT session token)"
      And subspec "users.feature" Requires: "session.feature -> AuthToken (JWT session token)"
      When the interface contract check runs
      Then the check status is FAIL
      And a finding is produced with check_type "WRONG_SOURCE"
      And the finding detail contains "users.feature requires AuthToken from session.feature but it is provided by auth.feature"

  Rule: No duplicate Provides

    Scenario: Two subspecs Provide the same ContractName
      Given subspec "auth.feature" Provides: "AuthToken (JWT session token)"
      And subspec "session.feature" Provides: "AuthToken (legacy session token)"
      When the interface contract check runs
      Then the check status is FAIL
      And a finding is produced with check_type "DUPLICATE_PROVIDES"
      And the finding detail contains "AuthToken is provided by both auth.feature and session.feature"

  Rule: No dependency cycles

    Scenario: Subspecs form a cycle A -> B -> A
      Given subspec "alpha.feature" Requires: "beta.feature -> BetaService (beta output)"
      And subspec "beta.feature" Requires: "alpha.feature -> AlphaService (alpha output)"
      And subspec "alpha.feature" Provides: "AlphaService (alpha output)"
      And subspec "beta.feature" Provides: "BetaService (beta output)"
      When the interface contract check runs
      Then the check status is FAIL
      And a finding is produced with check_type "DEPENDENCY_CYCLE"
      And the finding detail contains "alpha.feature -> beta.feature -> alpha.feature"

  Rule: File references in Requires must resolve to existing files

    Scenario: Requires references a file that does not exist
      Given subspec "users.feature" Requires: "nonexistent.feature -> Foo (some contract)"
      And "nonexistent.feature" does not exist in the spec directory
      When the interface contract check runs
      Then the check status is FAIL
      And a finding is produced with check_type "UNRESOLVABLE_SOURCE"
      And the finding detail contains "users.feature requires from nonexistent.feature but that file does not exist"

  Rule: Unconsumed Provides are advisory

    Scenario: A Provides is not referenced by any Requires
      Given subspec "auth.feature" Provides: "AuthToken (JWT session token)"
      And no subspec Requires: "AuthToken"
      When the interface contract check runs
      Then the check status is PASS
      And an advisory note is produced containing "AuthToken provided by auth.feature is not consumed by any subspec"
```

## Output

ANLZ-005 does not write a standalone inspection artifact. Its result is part of the Layout.Verify consistency check output. Implementations may emit the result to stdout for tooling use.

## Edge Cases

- **Subspec with no Requires and no Provides:** Valid — treated as a standalone subspec. No findings are produced.
- **Subspec with Provides but no Requires:** Valid — treated as a root node that exports a contract. No findings are produced.
- **Subspec with Requires but no Provides:** Valid — treated as a leaf node that consumes a contract. No findings are produced.
- **Missing Provides line on a subspec:** FAIL — `Provides:` is required per spec.md. A finding with check_type `MISSING` is produced for the subspec lacking the declaration.
