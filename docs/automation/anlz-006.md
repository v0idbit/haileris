# ANLZ-006: Field Hint Completeness

Fully mechanical consistency check. Validates that subspec `Provides:` entries include field hints and that `Requires:` field sets are subsets of the corresponding `Provides:` fields. Source: [layout.md](../stages/layout.md) (ANLZ-006 section).

**Tier:** M (fully mechanical). Parsing and set operations only.

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Subspec files | `tests/features/{deliverable}.feature` | Gherkin with `Requires:` and `Provides:` lines |

### Parsing Formats

**`Provides:` line:** Scan each subspec file for lines matching `Provides?:\s*(.+)`. Split the matched value on commas, trim whitespace. Each entry has format `{ContractName} (field1, field2 — description)`.

**`Requires:` line:** Scan each subspec file for lines matching `Requires?:\s*(.+)`. Split the matched value on commas, trim whitespace. Each entry has format `{file}.feature -> {ContractName} (field1, field2 — description)`.

**Field hint extraction:** For each entry, extract the parenthetical content. Split on the em dash (`—` or ASCII `---`). The left side contains comma-separated field hint identifiers (trim whitespace from each). The right side is the prose description (ignored by this check). If there is no em dash, the entire parenthetical is treated as having no field hints.

Reuses the same line-matching regex as [ANLZ-005](anlz-005.md) for `Requires:` and `Provides:` line detection.

## Behavior

```gherkin
Feature: ANLZ-006 Field Hint Completeness
  Validates that Provides: entries include field hints and that Requires:
  field sets are subsets of the corresponding Provides: fields.

  Background:
    Given the spec directory is "tests/features/"

  Rule: Every Provides must have field hints

    Scenario: A Provides entry has field hints
      Given subspec "auth.feature" Provides: "AuthToken (token_id, user_id, expiry — JWT session token)"
      When the field hint completeness check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A Provides entry has no field hints — no em dash
      Given subspec "auth.feature" Provides: "AuthToken (JWT session token)"
      When the field hint completeness check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING_FIELD_HINTS"
      And the finding detail contains "auth.feature Provides AuthToken with no field hints"

    Scenario: A Provides entry has no parenthetical
      Given subspec "auth.feature" Provides: "AuthToken"
      When the field hint completeness check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING_FIELD_HINTS"
      And the finding detail contains "auth.feature Provides AuthToken with no field hints"

    Scenario: A Provides entry has an em dash but nothing before it
      Given subspec "auth.feature" Provides: "AuthToken (— JWT session token)"
      When the field hint completeness check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING_FIELD_HINTS"
      And the finding detail contains "auth.feature Provides AuthToken with no field hints"

  Rule: Requires fields must be a subset of corresponding Provides fields

    Scenario: Requires field set is a subset of Provides fields
      Given subspec "auth.feature" Provides: "AuthToken (token_id, user_id, expiry — JWT session token)"
      And subspec "users.feature" Requires: "auth.feature -> AuthToken (token_id, user_id — session identity)"
      When the field hint completeness check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: Requires has a field not in Provides
      Given subspec "auth.feature" Provides: "AuthToken (token_id, user_id — JWT session token)"
      And subspec "users.feature" Requires: "auth.feature -> AuthToken (token_id, role — session identity)"
      When the field hint completeness check runs
      Then the check status is FAIL
      And a finding is produced with check_type "UNSATISFIED_FIELD"
      And the finding detail contains "users.feature requires field 'role' from AuthToken but auth.feature does not provide it"

  Rule: Requires with no field hints is valid

    Scenario: Requires has no field hints — description only
      Given subspec "auth.feature" Provides: "AuthToken (token_id, user_id — JWT session token)"
      And subspec "users.feature" Requires: "auth.feature -> AuthToken (JWT session token)"
      When the field hint completeness check runs
      Then the check status is PASS
      And an advisory note is produced containing "users.feature requires AuthToken with no field hints — consuming full contract"

  Rule: Unresolvable ContractName is deferred to ANLZ-005

    Scenario: Requires references a ContractName not found in any Provides
      Given subspec "users.feature" Requires: "auth.feature -> AuthToken (token_id — session identity)"
      And no subspec Provides: "AuthToken"
      When the field hint completeness check runs
      Then no finding is produced for "AuthToken" by ANLZ-006
      And the detail notes "ANLZ-005 handles unresolvable ContractName"
```

## Output

ANLZ-006 does not write a standalone inspection artifact. Its result is part of the Layout.Verify consistency check output. Implementations may emit the result to stdout for tooling use.

## Edge Cases

- **No parenthetical on a Provides entry:** FAIL with `MISSING_FIELD_HINTS`. The parenthetical is required to carry field hints.
- **Requires with no field hints:** PASS (advisory). The consumer accepts the full contract without narrowing. An advisory note is produced.
- **Em dash variants:** Both `—` (U+2014) and ASCII `---` are recognized as the em dash separator. Implementations must handle both.
- **Whitespace in field hints:** Field hint identifiers are trimmed of leading/trailing whitespace after splitting on commas.
- **Relationship to ANLZ-005:** ANLZ-006 does not validate ContractName resolution or graph structure — that is ANLZ-005's concern. If a `Requires:` references a ContractName not found in any `Provides:`, ANLZ-006 skips the subset check for that entry.
- **Multiple Provides on one line:** Each entry is checked independently. One entry with field hints and another without produces one FAIL finding.
