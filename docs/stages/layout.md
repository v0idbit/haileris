# 4. Layout

Break the Gherkin spec into small, vertical deliverables.

## Inputs

- Gherkin spec (primary spec + deliverable subspecs)
- Constitution

## Process

1. Read all BIDs from the spec directory (both `primary.feature` and `{deliverable}.feature` files); group related behaviors into discrete implementation tasks (each task has a coherent BID set, a shared implementation boundary, and is independently implementable). Primary BIDs from `primary.feature` are naturally placed in later tasks due to cross-deliverable dependencies.
2. Assign each task: `TASK-{NNN}` ID, description, BIDs covered, dependencies on other tasks, acceptance criteria
3. Verify each task's scope matches its BIDs (flag over-bundled or over-engineered tasks); revise per findings
4. Write ordered task list to `.haileris/features/{feature_id}/tasks.md`
5. Validate BID coverage; write `.haileris/features/{feature_id}/layout-inspection.yaml`
6. Present task list to user for approval (APPROVE / REJECT); wait for confirmation before proceeding to Etch
   - User may request task regrouping, reordering, or splitting — revise and re-validate if so
   - This gate catches over-bundled tasks, awkward groupings, or poor dependency ordering that the layout inspection cannot detect

## Outputs

- Gherkin subspec , each containing:
  - Enumerated Gherkin behavior tests (BIDs)
  - Technical details (common + per-BID deltas)
  - Delivery details per BID as needed

## Subspec Rules

- Separated by vertical slices
- Every subspec is disjoint from all others
- Union of all subspecs equals the full Gherkin spec

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Task list | `.haileris/features/{feature_id}/tasks.md` | Ingested by Etch and Realize; kept for inspection reference |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | Traceability gate input for Inspect |

## Layout Inspection

Validates the task list against Gherkin spec BIDs across 5 check types:

| Check | Condition |
|-------|-----------|
| MISSING | A Gherkin spec BID is absent from all tasks |
| HALLUCINATED | A BID in a task has no corresponding Gherkin spec entry |
| DUPLICATED | The same BID is the primary responsibility of more than one task |
| INSUFFICIENT | A task description is fewer than 10 words, or contains none of the keywords from the BID's Gherkin clauses |
| PARTIAL | A BID is split across tasks such that neither task alone covers its full acceptance criteria |

Overall `pass: true` only when all 5 check types produce zero findings.

On FAIL with `--fix`: up to 2 auto-revision passes; if still failing, escalate to user.

## Subspec Execution Order

Etch and Realize execute **sequentially per subspec** in task dependency order:

```
Etch(subspec 1) → Realize(subspec 1) → Etch(subspec 2) → Realize(subspec 2) → ...
```

This ordering ensures later subspecs can depend on earlier subspecs' implementations. The dependency order from Layout determines the sequence. All subspecs must complete before Inspect runs.

## Notes

- Task list is committed alongside other feature artifacts — useful for inspectioning task-to-BID mapping across retries
- `layout-inspection.yaml` is a Traceability Gate input at Inspect — a missing or failed inspection causes a Critical finding
- The layout inspection can be re-run on demand with `--fix` to attempt auto-repair