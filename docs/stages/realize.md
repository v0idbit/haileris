# 6. Realize

Implement each Gherkin subspec to make its red-phase tests pass.

## Inputs

- Gherkin subspec
- Red-phase tests for the Gherkin subspec
- Technical details
- Etch map (`etch-map.yaml`) — BID → test function mapping from Etch
- Constitution

## Process

1. For each subspec in dependency order, write production code that implements the behavior described by the subspec's BID scenarios (Gherkin spec = intent, tests = source of truth; test files are read-only from Etch forward). Source modules must be importable at the domain paths declared in the subspec's `Domains:` line, following the same naming conventions Etch used to derive import paths. The subspec's `Provides:` metadata defines the output contract this implementation must satisfy.
2. If tests still fail: analyze root cause; retry with findings — max 3 cycles per subspec; if still failing, escalate to user. If the failure is an import path mismatch, adjust source module structure to match the domain path convention before counting a retry cycle.
3. After each subspec's tests pass, map BIDs → derivations in `realize-map.yaml`
4. Validate the subspec's new map entries: every mapped derivation must exist in source and every BID must have at least one derivation entry. On FAIL: fix the mapping or escalate to user before proceeding to the next subspec.
5. After all subspecs complete, run the full test suite to confirm GREEN state
6. Validate the full Realize map; write `realize-inspection.yaml`

### Re-entry Behavior (Settle Loop)

When Realize is re-entered after a Settle loop:

1. Read `rerun_scope` from `pipeline-state.yaml`.
2. Skip Realize for subspecs not in the re-run scope. Their existing realize-map entries and implementation are preserved.
3. Re-run Realize normally for subspecs in scope. New realize-map entries replace old entries (merge semantics).
4. After a subspec completes, update its `provides_hash` in `subspec_statuses`. If the hash changed from the previous value, set `rerun_scope.provides_changed` to `true` — downstream dependents must re-run.
5. `_integration` always re-runs.

## Outputs

- Green-phase implementation for the Gherkin subspec

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Green-phase implementation | `src/` (repo) | Written directly to repo; also updated by Settle |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | BID → derivation mapping; built incrementally after each subspec |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | Traceability gate input for Inspect |

## Realize Inspection

Validates the Realize map after all subspecs complete. Three checks:

| Check | What it verifies |
|-------|-----------------|
| Completeness | Every Gherkin spec BID has at least one derivation entry in `realize-map.yaml` |
| Scope (AST) | Every derivation discovered by static analysis appears in the map under some BID |
| Broken refs | Every derivation in the map resolves to an existing source entity |

The realize inspection runs only after ALL subspecs complete and the full test suite is GREEN. Wait for full completion before running.

On FAIL: surface findings grouped by check type; pause; present options (fix manually, re-map specific subspecs, abort).

## Realize Map Format

```yaml
feature_id: "{feature_id}"
subspecs_completed: 3
subspecs_total: 3
bids:
  BID-001:
    derivations:
      - src/module#MyClass.my_method
    subspec: "users.feature"
```

## Notes

- Test files are read-only from Etch forward — Realize and Inspect treat them as fixed inputs (Settle applies a controlled three-tier fix policy for test-domain findings; see [Settle](settle.md))
- Source modules must be importable at the domain paths from the subspec's `Domains:` declarations — this is the shared import contract with Etch. If an import mismatch occurs, Realize adjusts its source structure to conform to the spec's domain paths (the spec is the authority)
- `realize-map.yaml` is built incrementally after each subspec; the realize inspection reads the final map
- `realize-inspection.yaml` is a Traceability Gate input at Inspect — missing or failed = Critical finding
- The realize inspection can be re-run on demand (no `--fix` available for build stage)
- After all subspecs' implementations pass, primary BID integration tests should also pass (since subspecs compose into primary scenarios per ANLZ-004). If any fail, treat as an implementation gap and retry.
- On re-entry, `realize-map.yaml` uses merge semantics.
- If Realize changes the implementation such that the `Provides:` contract changes, this triggers re-runs of downstream dependents via the `provides_changed` flag.
