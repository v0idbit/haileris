# Layout — Greenfield Construction

## Stage inputs

| Artifact | Path | Source |
|----------|------|--------|
| Primary spec (approved) | `tests/features/{feature_id}/primary.feature` | Inscribe; read-only from this point |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Governs `inspection_fixes` |

Layout reads exactly two artifacts: `primary.feature` and `constitution.md`. All inputs are spec-level.

## Stage outputs

| Artifact | Path |
|----------|------|
| Subspecs | `tests/features/{feature_id}/{deliverable}.feature` |
| `@traces` tags on primary spec | `tests/features/{feature_id}/primary.feature` |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` |

## Components to implement

### 1. Subspec decomposer (Layout.Decompose)

Implement a component that, given `primary.feature`, decomposes it into `{deliverable}.feature` subspecs. Each subspec:
- Owns one deliverable's behavioral contract
- Contains BIDs distributed from the primary spec — every primary BID appears in exactly one subspec
- Declares `Domains:` — module paths forming the shared import contract with Etch/Realize
- Declares `Requires:` — upstream data contracts consumed, with field hints
- Declares `Provides:` — downstream data contracts produced, with field hints

Subspecs inherit the behavioral level of the primary spec. Scenario steps describe observable behavior per deliverable. `Domains:` names module paths, `Requires:`/`Provides:` declare data contracts — but scenario steps themselves stay at the behavioral level. Implementation decisions (types, signatures, data shapes) begin at Etch.

### 2. `@traces` deriver (Layout.Decompose)

Implement a component that, after decomposition, adds `@traces` tags to `primary.feature`. Each primary scenario gets `@traces:BID-003,BID-015,...` listing the subspec BIDs it traces through.

**Derivation is self-contained:** the decomposer (component 1) distributes primary BIDs into subspecs. After distribution, the mapping is known. The sole inputs are the primary spec and the subspecs just created. The `@traces` deriver reads these and produces the tags — it requires no downstream artifacts (tests, source code, etc.).

### 3. Dependency order compiler (Layout.Decompose)

Implement a component that derives the delivery order from `Requires:` declarations:
- Parse `Requires: {file}.feature -> {ContractName}` as a dependency edge from the current subspec to `{file}.feature`
- A subspec with zero `Requires:` is a root node
- Topological sort produces the ordered list
- Detect cycles (ANLZ-005 validates acyclicity, but the compiler also rejects cyclic input)
- Append `_integration` as the final entry

Write `delivery-order.yaml` to `.haileris/features/{feature_id}/`.

### 4. ANLZ-003: Domain coverage (Layout.Verify)

Implement the 5-step trace-to-domain verification defined in [anlz-003.md](../../automation/anlz-003.md). Tier 1 (fully mechanical).

### 5. ANLZ-004: Composition validation (Layout.Verify)

Implement the 4-step trace/effect coverage check defined in [anlz-004.md](../../automation/anlz-004.md). Tier 3 (J-v): steps 1–2 (traces tag presence, BID existence) are always mechanical; steps 3–4 (effect coverage) are mechanical when Gherkin uses effect vocabulary, otherwise SKIP.

### 6. ANLZ-005: Interface contract consistency (Layout.Verify)

Implement the 6-step graph consistency check defined in [anlz-005.md](../../automation/anlz-005.md). Tier 1 (fully mechanical). Validates: every `Requires:` has a matching `Provides:`, the graph is acyclic, no duplicate `Provides:` across subspecs.

### 7. ANLZ-006: Field hint completeness (Layout.Verify)

Implement the 4-step field hint subset check defined in [anlz-006.md](../../automation/anlz-006.md). Tier 1 (fully mechanical). Validates: every `Provides:` has field hints, `Requires:` fields are a subset of corresponding `Provides:` fields.

### 8. Layout inspection (Layout.Verify)

Implement the 5-dimension BID coverage validation defined in [layout-inspection.md](../../automation/layout-inspection.md). Four dimensions are fully mechanical (MISSING, HALLUCINATED, DUPLICATED, INSUFFICIENT); one (PARTIAL) is agent-evaluated (SKIP). Output conforms to the [inspection report schema](../../artifacts/inspection-reports.md).

### 9. User approval gate (Layout.Approve)

Implement a user gate that presents subspecs, delivery order, and all check results:
- **Approve** → proceed to Etch
- **Request changes** → revise; re-run Layout.Verify; present again

### 10. Inspection auto-revision

When `inspection_fixes` > 0 in pipeline config, implement an auto-revision loop: on layout inspection failure, attempt fixes up to `inspection_fixes` passes before escalating.

## Orchestration

**Sub-stage ordering:** Decompose (sequential: decompose → `@traces` → dependency order → write files) → Verify (ANLZ-003 + ANLZ-004 + ANLZ-005 + ANLZ-006 + layout inspection) → Approve.

**State transitions:**
- Approve → advance pipeline state to Etch; initialize `subspec_statuses` in pipeline state via the Subspec Initialize operation ([pipeline-state.md](../../automation/pipeline-state.md))
- Request changes → re-run from Decompose or Verify as needed

## Scope boundaries

- Layout reads `primary.feature` and `constitution.md` only
- Layout writes to `tests/features/{feature_id}/` (subspecs, `@traces`) and `.haileris/features/{feature_id}/` (delivery order, inspection)
- `@traces` derivation is self-contained within Layout
- Implementation directories (`src/`, `tests/unit/`, `tests/integration/`) are Etch and Realize's responsibility

## Criteria reference

[Layout correctness criteria](../criteria/layout.md)
