# Etch — Greenfield Construction

## Stage inputs

| Artifact | Path | Source |
|----------|------|--------|
| Current subspec | `tests/features/{feature_id}/{deliverable}.feature` | Layout |
| Primary spec | `tests/features/{feature_id}/primary.feature` | Inscribe + Layout |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` | Layout |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Governs `etch_corrections`, `inspection_fixes` |
| Prior subspec implementations | `src/` from earlier Etch/Realize passes | Available after the first subspec cycle |

## Stage outputs

| Artifact | Path |
|----------|------|
| Unit tests (subspec BIDs) | `tests/unit/` |
| Integration tests (primary BIDs) | `tests/integration/` (final pass only) |
| Source stubs | `src/` at `Domains:` paths |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` |

## Subspec execution model

Implement a **subspec execution controller** that iterates subspecs per `delivery-order.yaml` dependency edges. A subspec enters Etch only after all subspecs it `Requires:` have completed Realize. Independent subspecs (no dependency path) may run concurrently; sequential is a valid default.

```
Sequential:  Etch(1) → Realize(1) → Etch(2) → Realize(2) → ...
Parallel:    Etch(A) → Realize(A) ─┐
                                    ├→ Etch(C) → Realize(C)
             Etch(B) → Realize(B) ─┘
```

After all subspec cycles complete, a **final Etch pass** produces integration tests for primary BIDs.

Track per-subspec progress via the Subspec Advance operation in [pipeline-state.md](../../automation/pipeline-state.md).

## Components to implement (per subspec)

### Implementation decisions begin here

Etch is the first stage where behavioral spec meets implementation. The Gherkin scenarios describe observable behavior in domain language; Etch translates that into concrete decisions. Implement the following components to handle this translation.

### 1. Data contract type definer

Implement a component that, given a subspec's `Provides:`/`Requires:` field hints and BID scenarios, produces named data contract type definitions (e.g., `UserRecord`, `AuthPayload`). These types give concrete shape to the field hints declared in subspec metadata.

When the subspec has `Requires:` contracts, the component references the data shapes declared in the upstream `Provides:` field hints for fixture design.

The same type definitions appear in both source stubs and test fixtures.

### 2. Source stub generator

Implement a component that creates stub modules at the subspec's `Domains:` paths:
- Named data contract type definitions (fully defined — these are the contracts)
- Function/method signatures with placeholder bodies (raise, return default, or language-equivalent stub marker)
- Module structure matching the `Domains:` import contract

Stubs establish the module structure and type contracts. Realize implements within these stubs — signatures and types are read-only from Etch forward.

### 3. Test generator

Implement a component that produces one test function per BID using AAA structure (Arrange, Act, Assert). Tests import from the stub modules — imports resolve immediately since stubs are in place.

When a subspec has `Requires:` contracts, fixtures reference the data shapes declared in the upstream `Provides:` field hints.

### 4. Etch-map writer

Implement a component that maps each BID to its test functions in `etch-map.yaml`. When processing multiple subspecs, the writer appends entries — implement merge semantics that preserve existing entries from prior subspec passes.

### 5. TEST-001: BID coverage gate

Implement the BID coverage check defined in [test-001.md](../../automation/test-001.md). Tier 1 (fully mechanical). Every BID in the current subspec must have at least one test function in the etch-map. When gaps are found, the test generator (component 3) adds missing tests.

### 6. RED state confirmer

Implement a component that runs the subspec's tests and verifies all fail with **assertion failure**. Stubs exist and imports resolve, but stub bodies return placeholder values — behavioral assertions fail against these placeholders.

When a test passes before Realize, implement the RED diagnostics defined in [red-diagnostics.md](../../automation/red-diagnostics.md). Tier 2 (M-c): mechanical when per-language default value tables and AAA structure are available.

| Cause | Correction |
|-------|------------|
| Default-value assertion | Strengthen to expect a specific value derived from the BID's Gherkin step |
| Tautological assertion | Rewrite to verify an observable effect from the BID's step |

Apply corrections up to `etch_corrections` passes (default: 0). Escalate when exhausted.

### 7. ANLZ-007: Data contract compliance

Implement the type annotation parsing and bare-generic detection defined in [anlz-007.md](../../automation/anlz-007.md). Tier 2 (M-c): fully mechanical when type annotation parsing is available for the target language. Validates **both** test function signatures and source stub signatures. Replace bare generics with named contract types when found.

### 8. Etch inspection

Implement the 5-dimension map validation defined in [etch-inspection.md](../../automation/etch-inspection.md). Three dimensions are fully mechanical (MISSING, HALLUCINATED, INSUFFICIENT); two (DUPLICATED, PARTIAL) are agent-evaluated (SKIP). Output conforms to the [inspection report schema](../../artifacts/inspection-reports.md).

### 9. Inspection auto-revision

When `inspection_fixes` > 0 in pipeline config, implement an auto-revision loop: on etch inspection failure, attempt fixes up to `inspection_fixes` passes before escalating.

## Final pass component

Implement an integration test generator that, after all subspec cycles complete, produces integration tests for primary BIDs at `tests/integration/`. These test end-to-end composition across subspecs. Create integration-level stubs at `Domains:` paths when new modules are needed.

## Orchestration (per subspec)

**Ordering:** Define types → Generate stubs → Generate tests → Write etch-map → TEST-001 → RED state confirm → ANLZ-007 → Etch inspection.

**After all subspecs:** Final integration test pass → advance pipeline state to Realize (which then runs per-subspec in the same dependency order).

## Scope boundaries

- Etch writes to `tests/unit/`, `tests/integration/`, `src/` at `Domains:` paths, and `.haileris/features/{feature_id}/`
- Stubs define structure and contracts only — placeholder bodies, with behavioral implementation deferred to Realize
- Gherkin spec files are untouched — Layout owns that path
- Import paths are derived from `Domains:` declarations and naming conventions (self-contained)

## Criteria reference

[Etch correctness criteria](../criteria/etch.md)
