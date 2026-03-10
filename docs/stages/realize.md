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
3. After each task's tests pass, map BIDs → source symbols in `realize-map.yaml`
4. After all tasks complete, run the full test suite to confirm GREEN state
5. Validate the implementation map; write `realize-inspection.yaml`

## Outputs

- Green-phase implementation for the Gherkin subspec

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Green-phase implementation | `src/` (repo) | Written directly to repo; also updated by Settle |
| Implementation map | `.haileris/features/{feature_id}/realize-map.yaml` | BID → source symbol mapping; built incrementally after each task |
| Build inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | Traceability gate input for Inspect; also written to session copy |

## Realize Inspection

Validates the implementation map after all tasks complete. Three checks:

| Check | What it verifies |
|-------|-----------------|
| Completeness | Every Gherkin spec BID has at least one symbol entry in `realize-map.yaml` |
| Scope (AST) | Every source symbol discovered by Python AST appears in the map under some BID (private helpers exempt) |
| Broken refs | Every symbol in the map actually exists in source (no ghost symbols) |

The realize inspection runs only after ALL tasks complete and the full test suite is GREEN. Do not run it mid-pipeline.

On FAIL: surface findings grouped by check type; pause; present options (fix manually, re-map specific tasks, abort).

## Implementation Map Format

```yaml
feature_id: "{feature_id}"
tasks_completed: 3
tasks_total: 3
bids:
  BID-001:
    symbols:
      - src/module.py::MyClass.my_method
    tasks: [TASK-1]
```

## Notes

- NEVER modify test files during this stage (or any stage after Etch)
- `realize-map.yaml` is built incrementally after each task; the realize inspection reads the final map
- `realize-inspection.yaml` is the third Traceability Gate input at Inspect — missing or failed = Critical finding
- The realize inspection can be re-run on demand (no `--fix` available for build stage)