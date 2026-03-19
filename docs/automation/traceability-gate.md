# Traceability Gate (Inspect.Gate)

Pre-review verification that all upstream inspection artifacts exist and passed. Source: [inspect.md](../stages/inspect.md) (Inspect.Gate section).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | YAML per [pipeline-state.md](../artifacts/pipeline-state.md) |
| Constitution | `.haileris/project/constitution.md` | Markdown (optional) |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |

**Version extraction:** The constitution version can be stored as YAML frontmatter, a heading, or a metadata field. The implementation must match the project's constitution format. If the constitution is plain markdown without machine-readable version, this check verifies file existence only.

## Behavior

```gherkin
Feature: Traceability Gate
  Pre-review verification that constitution version matches and all upstream
  inspection artifacts exist and passed.

  Background:
    Given the pipeline state is at ".haileris/features/{feature_id}/pipeline-state.yaml"
    And the constitution is at ".haileris/project/constitution.md"

  Rule: Constitution Version — recorded version must match current constitution

    Scenario: No constitution recorded and none exists
      Given the pipeline state has no recorded constitution version
      And "constitution.md" does not exist
      When the Constitution Version check runs
      Then the check status is PASS

    Scenario: Constitution exists but was not recorded at Harvest
      Given the pipeline state has no recorded constitution version
      And "constitution.md" exists
      When the Constitution Version check runs
      Then the check status is FAIL
      And a finding is produced with detail "Constitution exists but no version recorded in pipeline-state.yaml"

    Scenario: Constitution was recorded but the file is gone
      Given the pipeline state records constitution version "1.0"
      And "constitution.md" does not exist
      When the Constitution Version check runs
      Then the check status is FAIL
      And a finding is produced with detail "constitution.md not found but version was recorded"

    Scenario: Constitution version matches the recorded version
      Given the pipeline state records constitution version "1.0"
      And "constitution.md" exists with version "1.0"
      When the Constitution Version check runs
      Then the check status is PASS

    Scenario: Constitution version has changed since Harvest
      Given the pipeline state records constitution version "1.0"
      And "constitution.md" exists with version "2.0"
      When the Constitution Version check runs
      Then the check status is FAIL
      And a finding is produced with detail "Constitution changed since Harvest: recorded=1.0, current=2.0"

    Scenario: Pipeline state file is missing
      Given the pipeline state file does not exist
      When the Constitution Version check runs
      Then the check status is FAIL
      And a finding is produced with detail "pipeline-state.yaml not found"

  Rule: Inspection Artifacts — each upstream inspection must exist and have passed

    Scenario Outline: An inspection artifact exists and passed
      Given "<artifact>" exists and contains "pass: true"
      When the <artifact> check runs
      Then the check status is PASS

      Examples:
        | artifact                    |
        | harvest-inspection.yaml     |
        | layout-inspection.yaml      |
        | etch-inspection.yaml        |
        | realize-inspection.yaml     |

    Scenario Outline: An inspection artifact is missing
      Given "<artifact>" does not exist
      When the <artifact> check runs
      Then the check status is FAIL
      And a finding is produced with check_type "MISSING"
      And the finding detail contains "Critical: <artifact> not found"

      Examples:
        | artifact                    |
        | harvest-inspection.yaml     |
        | layout-inspection.yaml      |
        | etch-inspection.yaml        |
        | realize-inspection.yaml     |

    Scenario Outline: An inspection artifact exists but failed
      Given "<artifact>" exists and contains "pass: false" with <N> findings
      When the <artifact> check runs
      Then the check status is FAIL
      And a finding is produced with check_type "FAILED"
      And the finding detail contains "Critical: <artifact> failed with <N> finding(s)"

      Examples:
        | artifact                    | N |
        | harvest-inspection.yaml     | 2 |
        | layout-inspection.yaml      | 1 |
        | etch-inspection.yaml        | 3 |
        | realize-inspection.yaml     | 0 |
```

The four artifacts and their expected error messages on absence:

| Artifact | Critical message |
|----------|-----------------|
| `harvest-inspection.yaml` | "harvest-inspection.yaml not found; context coverage unverified" |
| `layout-inspection.yaml` | "layout-inspection.yaml not found; BID coverage for task list unverified" |
| `etch-inspection.yaml` | "etch-inspection.yaml not found; test BID mapping unverified" |
| `realize-inspection.yaml` | "realize-inspection.yaml not found; build BID mapping unverified" |

## Aggregation

The gate runs checks 1–5 in order (constitution version + 4 artifact checks). Overall status is PASS when all checks pass.

## Output

The traceability gate does not write its own inspection artifact. Its result is incorporated into the Inspect stage's verify report. Implementations may optionally write the result for debugging purposes.

## Edge Cases

- **All artifacts missing:** Each produces an independent Critical finding. The gate fails with 4 MISSING findings (plus any constitution finding).
- **Artifact exists but malformed YAML:** Treated as missing. The gate treats both "file not found" and "file unreadable" identically — both are gate blockers.
- **`pass` field absent from artifact:** If the YAML loads but has no `pass` key, treat as `pass: false`.
- **Constitution version is `null` in state:** This is the expected state when no constitution was present at Harvest. Only a problem if a constitution file now exists (Case 2).
