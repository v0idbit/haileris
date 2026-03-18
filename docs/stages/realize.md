# 6. Realize

Implement each Gherkin subspec to make its red-phase tests pass.

## Inputs

- Gherkin subspec
- Red-phase tests for the Gherkin subspec
- Etch map (`etch-map.yaml`) — BID → test function mapping from Etch
- Constitution

## Process

1. For each task in dependency order, write minimum production code to make the task's tests pass (Gherkin spec = intent, tests = source of truth; NEVER modify test files)
2. If tests still fail: analyze root cause; retry with findings — max 3 cycles per task; if still failing, escalate to user
3. After each task's tests pass, map BIDs → derivations in `realize-map.yaml`
4. Validate the task's new map entries: verify each mapped derivation exists in source (no broken refs) and each of the task's BIDs has at least one derivation entry (no missing mappings). On FAIL: fix the mapping or escalate to user before proceeding to the next task.
5. After all tasks complete, run the full test suite to confirm GREEN state
6. Validate the full implementation map; write `realize-inspection.yaml`

## Outputs

- Green-phase implementation for the Gherkin subspec

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Green-phase implementation | `src/` (repo) | Written directly to repo; also updated by Settle |
| Implementation map | `.haileris/features/{feature_id}/realize-map.yaml` | BID → derivation mapping; built incrementally after each task |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | Traceability gate input for Inspect; also written to session copy |

## Realize Inspection

Validates the implementation map after all tasks complete. Three checks:

| Check | What it verifies |
|-------|-----------------|
| Completeness | Every Gherkin spec BID has at least one derivation entry in `realize-map.yaml` |
| Scope (AST) | Every derivation discovered by static analysis appears in the map under some BID |
| Broken refs | Every derivation in the map actually exists in source (no ghost derivations) |

The realize inspection runs only after ALL tasks complete and the full test suite is GREEN. Do not run it mid-pipeline.

On FAIL: surface findings grouped by check type; pause; present options (fix manually, re-map specific tasks, abort).

## Implementation Map Format

```yaml
feature_id: "{feature_id}"
tasks_completed: 3
tasks_total: 3
bids:
  BID-001:
    derivations:
      - src/module#MyClass.my_method
    tasks: [TASK-1]
```

## Notes

- NEVER modify test files during this stage (or any stage after Etch)
- `realize-map.yaml` is built incrementally after each task; the realize inspection reads the final map
- `realize-inspection.yaml` is the third Traceability Gate input at Inspect — missing or failed = Critical finding
- The realize inspection can be re-run on demand (no `--fix` available for build stage)