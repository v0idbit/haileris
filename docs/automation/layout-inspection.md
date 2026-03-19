# Layout Inspection

Validates the task list against Gherkin spec BIDs. Source: [layout.md](../stages/layout.md) (Layout Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Task list | `.haileris/features/{feature_id}/tasks.md` | Markdown with `TASK-NNN` headings |

### BID Extraction

Spec BIDs are extracted by scanning all `.feature` files for `@BID-NNN` tags (regex `@(BID-\d+)`). The result is a set of unique BID identifiers.

### Task List Parsing

The task list is split at markdown headings matching `TASK-NNN`. For each task:
- **task_id**: the `TASK-NNN` identifier from the heading
- **description**: the remainder of the heading line (trimmed)
- **bids**: unique set of all `BID-\d+` matches in the task body (text between this heading and the next)
- **deps**: unique set of all `TASK-\d+` matches in the task body, excluding the task's own ID

The union of all task BIDs across all tasks forms the `task_bids` set.

## Behavior

```gherkin
Feature: Layout Inspection
  Validates the task list against Gherkin spec BIDs across 5 dimensions.

  Background:
    Given the spec files are in "tests/features/"
    And the task list is at ".haileris/features/{feature_id}/tasks.md"

  Rule: MISSING — every spec BID must appear in at least one task

    Scenario: All spec BIDs appear in the task list
      Given the spec contains BIDs "BID-001, BID-002"
      And the task list references BIDs "BID-001, BID-002"
      When the MISSING check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A spec BID is absent from all tasks
      Given the spec contains BIDs "BID-001, BID-002"
      And the task list references BIDs "BID-001"
      When the MISSING check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "MISSING"
      And the finding detail is "BID-002 has no task in the task list"

    Scenario: Multiple missing BIDs are reported in sorted order
      Given the spec contains BIDs "BID-001, BID-002, BID-003"
      And the task list references BIDs "BID-002"
      When the MISSING check runs
      Then the check status is FAIL
      And findings are produced for "BID-001, BID-003" with check_type "MISSING"
      And findings are reported in sorted BID order

  Rule: HALLUCINATED — every task BID must have a corresponding spec entry

    Scenario: All task BIDs exist in the spec
      Given the spec contains BIDs "BID-001, BID-002"
      And the task list references BIDs "BID-001, BID-002"
      When the HALLUCINATED check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A task references a BID not in the spec
      Given the spec contains BIDs "BID-001"
      And the task list references BIDs "BID-001, BID-002"
      When the HALLUCINATED check runs
      Then the check status is FAIL
      And a finding is produced for "BID-002" with check_type "HALLUCINATED"
      And the finding detail is "BID-002 is in task list but not in spec"

  Rule: DUPLICATED — a BID should appear in only one task

    Scenario: Each BID appears in exactly one task
      Given TASK-001 references BIDs "BID-001"
      And TASK-002 references BIDs "BID-002"
      When the DUPLICATED check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A BID appears in multiple tasks
      Given TASK-001 references BIDs "BID-001"
      And TASK-002 references BIDs "BID-001"
      When the DUPLICATED check runs
      Then the check status is FAIL
      And a finding is produced for "BID-001" with check_type "DUPLICATED"
      And the finding detail is "BID-001 appears in 2 tasks"

  Rule: INSUFFICIENT — task descriptions must be substantive and related to their BIDs

    Scenario: A task description has 10+ words and shares keywords with its BID scenarios
      Given TASK-001 has a description with 12 words
      And TASK-001 references BIDs "BID-001"
      And the Gherkin steps for "BID-001" share keywords with the task description
      When the INSUFFICIENT check runs
      Then the check status is PASS
      And no findings are produced

    Scenario: A task description has fewer than 10 words
      Given TASK-001 has a description with 5 words
      When the INSUFFICIENT check runs
      Then the check status is FAIL
      And a finding is produced for "TASK-001" with check_type "INSUFFICIENT"
      And the finding detail contains "TASK-001 description has 5 words (need ≥10)"

    Scenario: A task description shares no keywords with its BID scenarios
      Given TASK-001 has a description with 15 words
      And TASK-001 references BIDs "BID-001"
      And the Gherkin steps for "BID-001" share no keywords with the task description
      When the INSUFFICIENT check runs
      Then the check status is FAIL
      And a finding is produced for "TASK-001" with check_type "INSUFFICIENT"
      And the finding detail is "TASK-001 description shares no keywords with its BID scenarios"

    Scenario: A task has no BIDs — keyword overlap is not checked
      Given TASK-001 has a description with 15 words
      And TASK-001 references no BIDs
      When the INSUFFICIENT check runs
      Then no keyword-overlap finding is produced for "TASK-001"
```

Keyword extraction: For each BID, find the scenario tagged with `@{bid}` in the spec directory. Collect the text of all Given/When/Then/And/But steps in that scenario. Split into individual words (lowercased). Compare against words in the task description (case-insensitive).

### 5. PARTIAL — SKIP

Deferred (J-v: requires semantic coverage analysis). Returns `status: SKIP`.

## Aggregation

The inspection runs checks 1–5 in order. Overall status is PASS when all active checks pass.

## Output Path

`.haileris/features/{feature_id}/layout-inspection.yaml`

## Edge Cases

- **Empty task list:** All spec BIDs are MISSING. DUPLICATED and INSUFFICIENT produce no findings.
- **Task with no BIDs in body:** The task contributes nothing to `task_bids`. It will not cause HALLUCINATED findings but may indicate a malformed task.
- **Empty spec directory:** `spec_bids` is empty. HALLUCINATED catches any BIDs in tasks. MISSING produces no findings.
- **BID in heading vs. body:** Only BIDs found in the task *body* (between headings) are extracted. BIDs embedded in the heading line itself are not captured by the body scan.
