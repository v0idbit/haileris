# 6. Realize

Implement each Gherkin subspec to make its red-phase tests pass.

## Inputs

- Gherkin subspec
- Red-phase tests for the Gherkin subspec
- Etch map (`etch-map.yaml`) — BID → test function mapping from Etch
- Constitution

## Process

1. For each task in dependency order, write production code that implements the behavior described by the task's BID scenarios (Gherkin spec = intent, tests = source of truth; test files are read-only from Etch forward). Source modules must be importable at the domain paths declared in the subspec's `Domains:` line, following the same naming conventions Etch used to derive import paths.
2. If tests still fail: analyze root cause; retry with findings — max 3 cycles per task; if still failing, escalate to user. If the failure is an import path mismatch, adjust source module structure to match the domain path convention before counting a retry cycle.
3. After each task's tests pass, map BIDs → derivations in `realize-map.yaml`
4. Validate the task's new map entries: every mapped derivation must exist in source and every BID must have at least one derivation entry. On FAIL: fix the mapping or escalate to user before proceeding to the next task.
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
| Broken refs | Every derivation in the map resolves to an existing source entity |

The realize inspection runs only after ALL tasks complete and the full test suite is GREEN. Wait for full completion before running.

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

- Test files are read-only from Etch forward — all stages after Etch treat them as fixed inputs
- Source modules must be importable at the domain paths from the subspec's `Domains:` declarations — this is the shared import contract with Etch. If an import mismatch occurs, Realize adjusts its source structure to conform to the spec's domain paths (the spec is the authority)
- `realize-map.yaml` is built incrementally after each task; the realize inspection reads the final map
- `realize-inspection.yaml` is the third Traceability Gate input at Inspect — missing or failed = Critical finding
- The realize inspection can be re-run on demand (no `--fix` available for build stage)