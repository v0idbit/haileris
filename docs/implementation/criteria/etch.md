# Etch — Correctness Criteria

## Input Manifest

### Available at Etch entry

| Artifact | Path | Source |
|----------|------|--------|
| Gherkin subspec (current) | `tests/features/{feature_id}/{deliverable}.feature` | Written by Layout |
| Primary spec | `tests/features/{feature_id}/primary.feature` | Written by Inscribe, `@traces` added by Layout |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` | Written by Layout |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Written by Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Project-wide; governs `etch_corrections` and `inspection_fixes` |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Shows `layout: passed` |
| Prior subspec implementations (when current subspec has upstream dependencies) | `src/` paths from earlier subspec Etch/Realize passes | Available for subsequences after the first |

### Artifacts created by this stage

| Artifact | Path | Sub-stage |
|----------|------|-----------|
| Test files (subspec BIDs) | `tests/unit/` | Per-subspec pass |
| Test files (primary BIDs) | `tests/integration/` | Final pass |
| Source stubs | `src/` at `Domains:` paths | Per-subspec pass |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | Per-subspec pass |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | Per-subspec pass |

### Read scope

Etch reads the current subspec's `.feature` file (for BIDs, scenarios, `Domains:`, `Requires:`, `Provides:`), `technical-details.md` (for project conventions, test framework, naming patterns), `constitution.md` (for violation checks), and upstream subspec `Provides:` metadata (to inform test fixture design for `Requires:` contracts).

### Write scope

Etch writes to `tests/unit/` (subspec BIDs), `tests/integration/` (primary BIDs on the final pass), `src/` at `Domains:` paths (source stubs), and `.haileris/features/{feature_id}/` (etch-map, etch-inspection).

### Execution model

Etch and Realize execute **per subspec**, respecting the dependency edges in `delivery-order.yaml`. A subspec's Etch/Realize cycle runs only after all subspecs it `Requires:` have completed Realize. Subspecs with no dependency relationship may execute concurrently; sequential execution is a valid default strategy.

```
Sequential:  Etch(1) → Realize(1) → Etch(2) → Realize(2) → ...
Parallel:    Etch(A) → Realize(A) ─┐
                                    ├→ Etch(C) → Realize(C)
             Etch(B) → Realize(B) ─┘
```

After all subspec cycles complete, a **final Etch pass** writes integration tests for primary BIDs (end-to-end composition). Each Etch pass processes one subspec — the current subspec is the sole spec input for test generation.

## Behavioral Constraints

### Implementation decisions begin here

Etch is the first stage where behavioral spec meets implementation. The Gherkin scenarios describe observable behavior in domain language; Etch translates that into concrete implementation decisions:

- **Named data contract types** — Etch defines the contract types (e.g., `UserRecord`, `AuthPayload`) that satisfy the subspec's `Provides:` and `Requires:` declarations. These types give concrete shape to the field hints declared in subspec metadata. The type definitions are written to both test fixtures and source stubs.
- **Function signatures** — test functions establish the expected interface: parameter types, return types, and calling conventions. Source stubs mirror these signatures with placeholder bodies for Realize to implement.
- **Fixture design** — test Arrange sections define the concrete data shapes that flow through the system. When a subspec has `Requires:` contracts, fixtures reference the data shapes declared in the upstream `Provides:` field hints.
- **Source stubs** — Etch creates stub modules at the `Domains:` paths with data contract type definitions and function signatures. Stub bodies raise or return placeholder values — they exist to establish the module structure and type contracts that Realize implements within.

These decisions flow forward: Realize reads test files and source stubs as fixed inputs and fills in the implementations.

### How import paths are derived

Import paths come from the subspec's `Domains:` declarations and project naming conventions (from `technical-details.md`):
- `Domains:` provides the module root path
- Naming conventions provide entity names

Etch creates source stubs at these paths, so imports resolve immediately. Tests fail on assertions, with the stubs in place.

### RED state requirement

Every generated test fails. The expected failure mode is assertion failure — stubs exist and imports resolve, but stub bodies return placeholder values or raise, so behavioral assertions fail. When a test passes before Realize runs, apply the diagnostic protocol:

| Cause | Correction |
|-------|------------|
| **Default-value assertion** — matches a stub's placeholder return | Strengthen to expect a specific value derived from the BID's Gherkin step |
| **Tautological assertion** — true independent of production code | Rewrite to verify an observable effect from the BID's step |

Up to `etch_corrections` passes (see [pipeline config](../../artifacts/config.md); default: 0), then escalate to user when a test still passes after corrections are exhausted.

### Data contract compliance (ANLZ-007)

All test function parameters and return types use named data contract types for collections and compound types. Scalar primitives (`str`, `int`, `float`, `bool`) are allowed bare. The scope is limited to named contract types for everything else — bare generics (`dict`, `list`, `Any`, `object`, etc.) fall outside the allowed set. The same named types appear in both test files and source stubs.

### Test placement

| BID source | Test location |
|------------|---------------|
| Subspec BIDs | `tests/unit/` |
| Primary BIDs (final pass) | `tests/integration/` |

### Stub placement

| BID source | Stub location |
|------------|---------------|
| Subspec BIDs | `src/` at `Domains:` paths |
| Primary BIDs (final pass) | Integration-level stubs at `Domains:` paths when new modules are needed |

Stubs contain:
- Named data contract type definitions (fully defined — these are the contracts)
- Function/method signatures with placeholder bodies (raise, return default, or language-equivalent stub marker)
- Module structure matching the `Domains:` import contract

### Re-entry behavior (Settle loop)

On re-entry after Settle:
1. Read `rerun_scope` from `pipeline-state.yaml`
2. Preserve etch-map entries, test files, and stubs for subspecs outside the re-run scope
3. Re-run Etch for in-scope subspecs — new entries replace old (merge semantics); stubs are regenerated
4. `_integration` always re-runs when any subspec re-runs

## Sub-stage Ordering

Etch steps are sequential within each subspec pass:

1. Define named data contract types from the subspec's `Provides:`/`Requires:` field hints and BID scenarios
2. Write source stubs at `Domains:` paths — contract type definitions and function signatures with placeholder bodies
3. Write test functions (one per BID, AAA structure) importing from the stub modules
4. Write `etch-map.yaml` mapping each BID to its test functions
5. Verify every BID has at least one test function via the map (TEST-001 gate); add missing tests when needed
6. Run tests to confirm RED state (TEST-002 gate); apply diagnostic protocol for any passing tests
7. Validate the map across 5 check types; write `etch-inspection.yaml`
8. Run ANLZ-007 on all test function signatures and stub signatures; replace bare generics with named contract types when found

## Exit Checks

### Artifact existence

- [ ] Test files exist at appropriate locations (`tests/unit/` for subspec BIDs, `tests/integration/` for primary BIDs)
- [ ] Source stubs exist at `src/` paths matching `Domains:` declarations
- [ ] `etch-map.yaml` exists at `.haileris/features/{feature_id}/etch-map.yaml`
- [ ] `etch-inspection.yaml` exists at `.haileris/features/{feature_id}/etch-inspection.yaml`

### Stub integrity

- [ ] Every stub module is importable at its `Domains:` path
- [ ] Every named data contract type from tests is defined in the corresponding stub
- [ ] Every function signature tested has a matching stub signature with a placeholder body
- [ ] Stubs contain type definitions and signatures only — behavioral implementation is Realize's responsibility

### BID coverage

- [ ] Every BID in the current subspec has at least one test function in the etch-map (TEST-001)
- [ ] Every BID in the etch-map traces back to a subspec entry (HALLUCINATED check)
- [ ] Every mapped test function body is 3+ lines of content (INSUFFICIENT check)

### RED state

- [ ] All tests fail (TEST-002)
- [ ] Failure mode is assertion failure against stub placeholder returns — imports resolve, stubs are in place

### Data contracts

- [ ] All test function parameters and return types use named contract types for collections/compound types (ANLZ-007)
- [ ] All stub function parameters and return types use named contract types for collections/compound types (ANLZ-007)
- [ ] The allowed set for type annotations is: named contract types and scalar primitives

### Inspection result

- [ ] `etch-inspection.yaml` records results for all 5 check types
- [ ] Mechanically verified checks (MISSING, HALLUCINATED, INSUFFICIENT) pass

### Boundary discipline

- [ ] Etch's write scope is `tests/unit/`, `tests/integration/`, `src/` at `Domains:` paths, and `.haileris/features/{feature_id}/`
- [ ] Stubs define structure and contracts only — placeholder bodies, with behavioral implementation deferred to Realize
- [ ] Gherkin spec files are untouched — Layout owns that path
- [ ] Import paths are derived from `Domains:` declarations and naming conventions (spec-derived, self-contained)
