# 5. Etch

Write red-phase tests for each Gherkin subspec.

## Inputs

- Gherkin subspec
- Constitution

## Process

1. Write one test function per BID behavior in AAA (Arrange / Act / Assert) structure; import not-yet-existing source modules so all tests fail at import time. Import paths derive from the subspec's `Domains:` declarations (domain path) and project naming conventions (entity names) — the agent derives all import paths from these conventions. Primary BIDs produce integration tests (e.g., `tests/integration/`); subspec BIDs produce unit tests (e.g., `tests/unit/`). Exact directory names and test framework follow project conventions. Test assertions must verify observable effects from the BID's Gherkin Then/And steps: state changes, outputs produced, and data passed between components.
2. Write `etch-map.yaml` mapping each BID to its test functions
3. Verify every BID has at least one test function via the map (TEST-001 gate); if FAIL, add missing tests and update the map
4. Run the test suite to confirm RED state (TEST-002 gate) — every generated test must fail. For each passing test, apply the diagnostic protocol (see RED State Confirmation); re-run after corrections. Escalate to user when any test still passes after one correction pass.
5. Validate the map across 5 check types; write `.haileris/features/{feature_id}/etch-inspection.yaml`

## Outputs

- Red-phase tests for the Gherkin subspec

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Primary BID tests | `tests/integration/` (repo) | End-to-end tests from primary BIDs; written to repo test tree |
| Subspec BID tests | `tests/unit/` (repo) | Per-deliverable tests from subspec BIDs; written to repo test tree |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | BID → test function map; validated by Etch Inspection and ingested by Inspect |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | Traceability gate input for Inspect |

All tests are source artifacts — always stored in the repo's test directories.

## Etch Inspection

Validates `etch-map.yaml` across 5 check types:

| Check | Condition |
|-------|-----------|
| MISSING | A Gherkin spec BID is absent from the map |
| HALLUCINATED | A BID in the map has no corresponding Gherkin spec entry |
| DUPLICATED | The same BID maps to more than one substantially similar test function |
| INSUFFICIENT | A mapped test function body is fewer than 3 lines (excluding doc comments, annotations, blanks) |
| PARTIAL | A BID's mapped tests leave one or more Gherkin Then clauses uncovered |

On FAIL with `--fix`: up to 2 auto-revision passes; if still failing, escalate to user.

## RED State Confirmation

Every test must require production code to pass. Import/build failure on source modules pending creation by Realize is the expected failure mode; this protocol handles tests that pass before Realize creates production code. For each passing test, identify the cause and apply the prescribed correction:

| Cause | Detection | Correction |
|-------|-----------|------------|
| **Existing import** — import resolves to a pre-existing module (stdlib, third-party, prior feature) | Import path resolves to a module outside the feature's `Domains:` paths | Update import to target the domain path from `Domains:` declarations (module exists only after Realize) |
| **Default-value assertion** — asserted value matches a language default (None, null, 0, "", []) | Expected value in the assertion is a language default for the return type | Strengthen assertion to expect a specific value derived from the BID's Gherkin Then/And step and the test's Arrange data |
| **Tautological assertion** — assertion references only Arrange-section data or evaluates to true unconditionally | Assertion holds true independent of production code execution | Rewrite to verify an observable effect from the BID's Gherkin Then/And step |

Assertion corrections in this table use the same closed-derivation-scope principle as Settle tier 2: derive the expected value from the Gherkin step and the test's Arrange data only.

One correction pass, then re-run. Escalate to user when a test still passes after correction — the test requires regeneration.

## Notes

- Test naming convention follows the project's test framework (e.g., `test_create_user`) — BID traceability is carried by `etch-map.yaml`, not by test names
- `etch-map.yaml` format: each BID key lists the fully-qualified test function paths that cover it (e.g., `tests/integration/test_workflow#test_full_pipeline` for primary BIDs, `tests/unit/test_feature#test_create_user` for subspec BIDs). The `#` separates the file path from the function name.
- `etch-inspection.yaml` is a Traceability Gate input at Inspect — missing or failed = Critical finding
- The etch inspection can be re-run on demand with `--fix` to attempt auto-repair
- See RED State Confirmation above for the full diagnostic protocol applied to passing tests
- Import paths are derived from the subspec's `Domains:` declarations and project naming conventions — `Domains:` provides the module root, naming conventions provide entity names. This makes import paths a shared contract with Realize (see [spec Domains metadata](../artifacts/spec.md#pipeline-metadata))
- After all subspec Etch→Realize cycles complete and the full suite is green, a final Etch pass writes integration tests for primary BIDs. These verify end-to-end composition (the wiring that `@traces` tags describe). The etch-map includes primary BIDs.
