# 5. Etch

Write red-phase tests for each Gherkin subspec.

## Inputs

- Gherkin subspec
- Constitution

## Process

1. Write one test function per BID behavior in AAA (Arrange / Act / Assert) structure; import not-yet-existing source modules so all tests fail at import time. Primary spec BIDs produce integration tests (e.g., `tests/integration/`); subspec BIDs produce unit tests (e.g., `tests/unit/`) and/or behavior tests (e.g., `tests/features/`). Exact directory names and test framework follow project conventions.
2. Write `etch-map.yaml` mapping each BID to its test functions
3. Verify every BID has at least one test function via the map (TEST-001 gate); if FAIL, add missing tests and update the map
4. Run the test suite to confirm RED state — all generated tests must fail; if any test passes before implementation, fix it (TEST-002 failure)
5. Validate the map across 5 check types; write `.haileris/features/{feature_id}/etch-inspection.yaml`

## Outputs

- Red-phase tests for the Gherkin subspec

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Integration tests (primary BIDs) | `tests/integration/` (repo) | End-to-end tests from primary spec BIDs; written to repo test tree |
| Unit/behavior tests (subspec BIDs) | `tests/unit/`, `tests/features/` (repo) | Per-concern tests from subspec BIDs; written to repo test tree |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | BID → test function map; validated by Etch Inspection and ingested by Inspect |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | Traceability gate input for Inspect |

All tests are source artifacts in the repo's test directories — never stored in `.haileris/`.

## Etch Inspection

Validates `etch-map.yaml` across 5 check types:

| Check | Condition |
|-------|-----------|
| MISSING | A Gherkin spec BID has no test functions in the map |
| HALLUCINATED | A BID in the map does not exist in the Gherkin spec |
| DUPLICATED | The same BID maps to more than one substantially similar test function |
| INSUFFICIENT | A mapped test function body is fewer than 3 lines (excluding doc comments, annotations, blanks) |
| PARTIAL | A BID's mapped tests do not collectively cover all its Gherkin Then clauses |

On FAIL with `--fix`: up to 2 auto-revision passes; if still failing, escalate to user.

## Notes

- Test naming convention follows the project's test framework (e.g., `test_create_user`) — BID traceability is carried by `etch-map.yaml`, not by test names
- `etch-map.yaml` format: each BID key lists the fully-qualified test function paths that cover it (e.g., `tests/integration/test_workflow#test_full_pipeline` for primary BIDs, `tests/unit/test_feature#test_create_user` for subspec BIDs). The `#` separates the file path from the symbol name.
- `etch-inspection.yaml` is a Traceability Gate input at Inspect — missing or failed = Critical finding
- The etch inspection can be re-run on demand with `--fix` to attempt auto-repair
- Do not proceed until RED state is confirmed; import/build failure on missing source modules is the expected failure mode
