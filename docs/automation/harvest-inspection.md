# Harvest Inspection

Validates `decomposition.md` and `technical-details.md` across 4 dimensions. Source: [harvest.md](../stages/harvest.md) (Harvest Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Markdown with section headings |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Markdown with section headings |
| Standards memory | `.haileris/project/standards.md` | Markdown |
| Test conventions memory | `.haileris/project/test-conventions.md` | Markdown |

`has_non_empty_section(content, name)`: scan for a markdown heading (any level) whose text contains `name` (case-insensitive). Return true if at least one non-blank line exists between that heading and the next heading (or end of file).

`count_non_blank_lines(path)`: read file, count lines where `strip(line)` is non-empty.

## Behavior

```gherkin
Feature: Harvest Inspection
  Validates decomposition.md, technical-details.md, and project memory artifacts.

  Background:
    Given the feature directory is ".haileris/features/{feature_id}/"
    And the project directory is ".haileris/project/"

  Rule: DECOMPOSITION_TEMPLATE — decomposition.md contains required sections with content

    Scenario: decomposition.md has all required sections with content
      Given "decomposition.md" exists in the feature directory
      And "decomposition.md" contains a non-empty "Description" section
      And "decomposition.md" contains a non-empty "Delivery Details" section
      When the DECOMPOSITION_TEMPLATE check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: decomposition.md is missing
      Given "decomposition.md" does not exist in the feature directory
      When the DECOMPOSITION_TEMPLATE check runs
      Then the check status is FAIL
      And a finding is produced with detail "decomposition.md not found"

    Scenario: decomposition.md is missing a required section
      Given "decomposition.md" exists in the feature directory
      And "decomposition.md" does not contain a non-empty "Description" section
      When the DECOMPOSITION_TEMPLATE check runs
      Then the check status is FAIL
      And a finding is produced with check_type "INSUFFICIENT" and detail "missing or empty section: Description"

    Scenario: A required section has a heading but no content lines
      Given "decomposition.md" exists in the feature directory
      And "decomposition.md" contains a "Delivery Details" heading with no non-blank lines below it
      When the DECOMPOSITION_TEMPLATE check runs
      Then the check status is FAIL
      And a finding is produced with check_type "INSUFFICIENT" and detail "missing or empty section: Delivery Details"

  Rule: TECHNICAL_DETAILS_TEMPLATE — technical-details.md contains required sections with content

    Scenario: technical-details.md has all required sections with content
      Given "technical-details.md" exists in the feature directory
      And "technical-details.md" contains non-empty sections for "Standards", "Test Conventions", and "Dependencies"
      When the TECHNICAL_DETAILS_TEMPLATE check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: technical-details.md is missing
      Given "technical-details.md" does not exist in the feature directory
      When the TECHNICAL_DETAILS_TEMPLATE check runs
      Then the check status is FAIL
      And a finding is produced with detail "technical-details.md not found"

    Scenario Outline: A required section is missing or empty
      Given "technical-details.md" exists in the feature directory
      And "technical-details.md" does not contain a non-empty "<section>" section
      When the TECHNICAL_DETAILS_TEMPLATE check runs
      Then the check status is FAIL
      And a finding is produced with check_type "INSUFFICIENT" and detail "missing or empty section: <section>"

      Examples:
        | section          |
        | Standards        |
        | Test Conventions |
        | Dependencies     |

  Rule: ARTIFACT_PREFLIGHT — project memory artifacts exist and have substantive content

    Scenario: Both project artifacts exist and exceed the line threshold
      Given "standards.md" exists in the project directory with more than 5 non-blank lines
      And "test-conventions.md" exists in the project directory with more than 5 non-blank lines
      When the ARTIFACT_PREFLIGHT check runs
      Then the check status is PASS
      And no findings are produced

    Scenario Outline: A project artifact is missing
      Given "<artifact>" does not exist in the project directory
      When the ARTIFACT_PREFLIGHT check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING" and detail "<artifact> not found"

      Examples:
        | artifact             |
        | standards.md         |
        | test-conventions.md  |

    Scenario: A project artifact exists but has too few non-blank lines
      Given "standards.md" exists in the project directory with 3 non-blank lines
      When the ARTIFACT_PREFLIGHT check runs
      Then the check status is FAIL
      And a finding is produced with check_type "INSUFFICIENT" and detail "standards.md has 3 non-blank lines (need >5)"
```

### 4. Dependency Doc Coverage — SKIP

Deferred. Returns `status: SKIP` with detail "Dependency doc coverage check deferred (requires package resolution)".

## Aggregation

The inspection runs checks 1–4 in order. Overall status is PASS when checks 1–3 pass. Check 4 (SKIP) does not affect the result.

## Output Path

`.haileris/features/{feature_id}/harvest-inspection.yaml`

## Edge Cases

- **Empty file:** A file that exists but contains only whitespace has 0 non-blank lines. Treated as insufficient for both template checks and artifact preflight.
- **Heading-only section:** A section heading with no content lines before the next heading fails `has_non_empty_section`.
- **Missing feature directory:** If the feature directory itself is absent, all checks fail with MISSING findings.
