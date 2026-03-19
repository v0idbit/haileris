# ANLZ-003: Domain Coverage

Fully mechanical consistency check. Verifies that every subspec referenced by primary scenario `@traces` tags has declared `Domains:` metadata. Source: [inscribe.md](../stages/inscribe.md) (ANLZ-003 section).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Primary spec | `tests/features/primary.feature` | Gherkin with `@traces` tags |
| Subspec files | `tests/features/{deliverable}.feature` | Gherkin with `Domains:` lines |

### Gherkin Metadata Formats

**`@traces` tag** on primary spec scenarios:
```gherkin
@BID-050 @traces:BID-003,BID-015,BID-024
Scenario: Full user workflow
```

**`Domains:` line** in subspec files (typically in a comment or description block):
```
Domains: src/users, src/auth
```

Multiple domains are comma-separated. The `Domains:` line may use singular or plural form (`Domain:` or `Domains:`).

### Parsing Formats

**Domains extraction:** Scan each subspec file for lines matching `Domains?:\s*(.+)` (case-sensitive, supports singular or plural). Split the matched value on commas, trim whitespace. An empty or whitespace-only value is treated as no domains.

**Traces extraction:** Scan the primary spec for lines containing `@traces:`. Extract the comma-separated BID list. The parent BID is the `@BID-NNN` tag on the same line or the nearest preceding line.

**BID-to-file resolution:** For a given BID, scan all `.feature` files for the tag `@{bid}`. Return the first file containing it.

## Behavior

```gherkin
Feature: ANLZ-003 Domain Coverage
  Verifies that every subspec referenced by primary scenario @traces tags
  has declared Domains: metadata.

  Background:
    Given the spec directory is "tests/features/"
    And "primary.feature" exists in the spec directory

  Rule: Subspec domain declarations — every subspec must have a Domains: line

    Scenario: All subspecs have Domains: declarations
      Given subspec "users.feature" has Domains: "src/users"
      And subspec "auth.feature" has Domains: "src/auth"
      When domain declarations are checked
      Then no findings are produced for missing domain declarations

    Scenario: A subspec has no Domains: declaration
      Given subspec "users.feature" has no Domains: line
      When domain declarations are checked
      Then a finding is produced with check_type "MISSING"
      And the finding detail is "Subspec users.feature has no Domains: declaration"

    Scenario: A subspec has an empty Domains: value
      Given subspec "users.feature" has Domains: "   "
      When domain declarations are checked
      Then a finding is produced with check_type "MISSING"
      And the finding detail is "Subspec users.feature has no Domains: declaration"

  Rule: Trace resolution — traced BIDs must resolve to subspecs with domains

    Scenario: All traced BIDs resolve to subspecs with domains
      Given primary scenario "BID-050" traces "BID-003, BID-015"
      And "BID-003" is in subspec "users.feature" which has Domains: "src/users"
      And "BID-015" is in subspec "auth.feature" which has Domains: "src/auth"
      When the domain coverage check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A traced BID resolves to a subspec without domains
      Given primary scenario "BID-050" traces "BID-003"
      And "BID-003" is in subspec "users.feature" which has no Domains: declaration
      When the domain coverage check runs
      Then the check status is FAIL
      And a finding is produced for "BID-050" with check_type "MISSING"
      And the finding detail contains "traces through users.feature via BID-003, but that subspec has no Domains: declaration"

    Scenario: A traced BID is not found in any subspec
      Given primary scenario "BID-050" traces "BID-099"
      And "BID-099" does not appear in any subspec file
      When the domain coverage check runs
      Then the check status is FAIL
      And a finding is produced for "BID-050" with check_type "MISSING"
      And the finding detail contains "traces BID-099 but BID not found in any subspec"

    Scenario: A traced BID resolves to the primary spec itself
      Given primary scenario "BID-050" traces "BID-051"
      And "BID-051" is in "primary.feature"
      When the domain coverage check runs
      Then no finding is produced for the "BID-050" → "BID-051" trace

    Scenario: primary.feature does not exist
      Given "primary.feature" does not exist in the spec directory
      When the domain coverage check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING"
      And the finding detail is "primary.feature not found"
```

## Output

ANLZ-003 does not write a standalone inspection artifact. Its result is part of the Inscribe.Verify consistency check output. Implementations may emit the result to stdout for tooling use.

## Edge Cases

- **No subspecs:** If only `primary.feature` exists, no domain-declaration findings are produced. Trace resolution will produce MISSING findings for any traced BIDs that don't resolve.
- **Subspec with `Domains:` but empty value:** `Domains:   ` (whitespace only) is treated as no domains — same as missing the line.
- **BID in multiple files:** BID-to-file resolution returns the first file found. BIDs should be unique across files; duplicate BIDs are a separate validation concern.
- **Primary scenario without `@traces`:** No entries in the traces map for that scenario. ANLZ-003 does not flag this — it only checks scenarios that *have* traces. Missing `@traces` tags are an ANLZ-004 concern.
- **Traced BID resolves to primary.feature:** Skip — primary self-references are not domain coverage issues. This happens when a primary scenario traces another primary BID.
