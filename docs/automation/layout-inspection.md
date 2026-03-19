# Layout Inspection

Validates the task list against Gherkin spec BIDs. Source: [layout.md](../stages/layout.md) (Layout Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Task list | `.haileris/features/{feature_id}/tasks.md` | Markdown with `TASK-NNN` headings |

## Prerequisite: BID and Task Extraction

Both are shared across checks.

### Extract Spec BIDs

```
FUNCTION extract_spec_bids(spec_dir):
  bids ← empty set
  FOR EACH file IN glob(spec_dir, "*.feature"):
    content ← read(file)
    FOR EACH match OF regex "@(BID-\d+)" IN content:
      bids.add(match.group(1))
  RETURN bids
```

### Parse Task List

```
FUNCTION parse_tasks(task_list_path):
  content ← read(task_list_path)
  tasks ← empty list

  Split content at markdown headings matching regex "^#+\s*(TASK-\d+)\b(.*)"
  FOR EACH heading match:
    task_id   ← captured TASK-NNN
    description ← remainder of heading line (trimmed)
    body      ← text between this heading and the next TASK heading (or EOF)
    bids      ← unique set of all "BID-\d+" matches in body
    deps      ← unique set of all "TASK-\d+" matches in body, excluding task_id

    APPEND TaskEntry(task_id, description, bids, deps) to tasks

  RETURN tasks
```

### Collect Task BIDs

```
task_bids ← union of all task.bids for each task in tasks
```

## Checks

### 1. MISSING

A Gherkin spec BID is absent from all tasks.

```
FUNCTION check_missing(spec_bids, task_bids):
  missing ← spec_bids − task_bids    — set difference

  FOR EACH bid IN sorted(missing):
    ADD finding(bid, check_type="MISSING", detail="{bid} has no task in the task list")

  RETURN PASS if missing is empty, FAIL otherwise
```

### 2. HALLUCINATED

A BID in a task has no corresponding Gherkin spec entry.

```
FUNCTION check_hallucinated(spec_bids, task_bids):
  hallucinated ← task_bids − spec_bids

  FOR EACH bid IN sorted(hallucinated):
    ADD finding(bid, check_type="HALLUCINATED", detail="{bid} is in task list but not in spec")

  RETURN PASS if hallucinated is empty, FAIL otherwise
```

### 3. DUPLICATED

The same BID is the primary responsibility of more than one task.

```
FUNCTION check_duplicated(tasks):
  bid_count ← empty map of BID → integer

  FOR EACH task IN tasks:
    FOR EACH bid IN task.bids:
      bid_count[bid] ← bid_count[bid] + 1

  FOR EACH (bid, count) IN bid_count WHERE count > 1:
    ADD finding(bid, check_type="DUPLICATED", detail="{bid} appears in {count} tasks")

  RETURN PASS if no findings, FAIL otherwise
```

### 4. INSUFFICIENT

A task description is fewer than 10 words, or contains none of the keywords from the BID's Gherkin clauses.

```
FUNCTION check_insufficient(tasks, spec_dir):
  FOR EACH task IN tasks:
    words ← split(task.description, on whitespace)

    IF length(words) < 10:
      ADD finding(task.task_id, check_type="INSUFFICIENT",
                  detail="{task_id} description has {length(words)} words (need ≥10)")
      CONTINUE to next task

    — Keyword overlap check
    FOR EACH bid IN task.bids:
      keywords ← extract_gherkin_step_keywords(spec_dir, bid)
      — keywords = set of step text words from the BID's scenario
      IF any keyword appears in task.description (case-insensitive):
        mark task as having overlap
        BREAK

    IF task has BIDs AND no keyword overlap was found:
      ADD finding(task.task_id, check_type="INSUFFICIENT",
                  detail="{task_id} description shares no keywords with its BID scenarios")

  RETURN PASS if no findings, FAIL otherwise
```

`extract_gherkin_step_keywords(spec_dir, bid)`: find the scenario tagged with `@{bid}` in the spec directory. Collect the text of all Given/When/Then/And/But steps in that scenario. Split into individual words (lowercased). Return as a set.

### 5. PARTIAL — SKIP

Deferred (J-v: requires semantic coverage analysis). Returns `status: SKIP`.

## Aggregation

```
FUNCTION run_layout_inspection(feature_dir, spec_dir):
  spec_bids ← extract_spec_bids(spec_dir)
  tasks     ← parse_tasks(feature_dir / "tasks.md")
  task_bids ← union of all task.bids

  checks ← [
    check_missing(spec_bids, task_bids),
    check_hallucinated(spec_bids, task_bids),
    check_duplicated(tasks),
    check_insufficient(tasks, spec_dir),
  ]

  pass ← all active checks have status PASS
  RETURN InspectionResult(timestamp=now_utc(), pass, checks, flatten(findings))
```

## Output Path

`.haileris/features/{feature_id}/layout-inspection.yaml`

## Edge Cases

- **Empty task list:** All spec BIDs are MISSING. DUPLICATED and INSUFFICIENT produce no findings.
- **Task with no BIDs in body:** The task contributes nothing to `task_bids`. It will not cause HALLUCINATED findings but may indicate a malformed task.
- **Empty spec directory:** `spec_bids` is empty. HALLUCINATED catches any BIDs in tasks. MISSING produces no findings.
- **BID in heading vs. body:** Only BIDs found in the task *body* (between headings) are extracted. BIDs embedded in the heading line itself are not captured by the body scan.
