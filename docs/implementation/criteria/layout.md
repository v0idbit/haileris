# Layout — Correctness Criteria

## Input Manifest

### Available at Layout entry

| Artifact | Path | Source |
|----------|------|--------|
| Primary spec | `tests/features/{feature_id}/primary.feature` | Written by Inscribe; `@status:approved`; read-only from this point forward |
| Constitution | `.haileris/project/constitution.md` | Project-wide; read-only |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Project-wide; governs `inspection_fixes` |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Shows `inscribe: passed` |

### Artifacts created by this stage

| Artifact | Path | Sub-stage |
|----------|------|-----------|
| Subspecs (`{deliverable}.feature`) | `tests/features/{feature_id}/` | Layout.Decompose |
| `@traces` tags on `primary.feature` | `tests/features/{feature_id}/primary.feature` | Layout.Decompose |
| `delivery-order.yaml` | `.haileris/features/{feature_id}/` | Layout.Decompose |
| `layout-inspection.yaml` | `.haileris/features/{feature_id}/` | Layout.Verify |

### Read scope

Layout reads exactly two artifacts: `primary.feature` (for BIDs, scenario steps, and structure) and `constitution.md` (for violation checks). All inputs to Layout are spec-level — the primary spec and the subspecs that Layout itself creates.

### Write scope

Layout writes to `tests/features/{feature_id}/` (subspecs and `@traces` tags on primary spec) and `.haileris/features/{feature_id}/` (delivery order and layout inspection). Implementation directories (`src/`, `tests/unit/`, `tests/integration/`) are Etch and Realize's responsibility.

## Behavioral Constraints

### How `@traces` tags are derived

`@traces` tags record the mapping from primary scenarios to subspec BIDs. This mapping is a direct byproduct of decomposition:

1. Layout.Decompose distributes primary BIDs into subspecs (step 2).
2. After distribution, the mapping is known: each primary scenario's BIDs landed in specific subspecs.
3. Layout writes that mapping as `@traces:BID-003,BID-015,...` tags on primary scenarios (step 4).

The sole inputs are the primary spec and the subspecs that Layout itself just created. `@traces` derivation is self-contained within the decomposition.

### How `delivery-order.yaml` is derived

Compiled from `Requires:` and `Provides:` declarations in the subspecs that Layout just created. Topological sort of the dependency graph. A subspec with zero `Requires:` entries is a root node.

### How subspecs are created

Decomposed from primary spec scenarios. Each subspec:
- Owns one deliverable's behavioral contract
- Contains BIDs distributed from the primary spec
- Declares `Domains:`, `Requires:`, `Provides:` metadata
- Every primary BID appears in exactly one subspec

### Behavioral level

Subspecs inherit the behavioral level of the primary spec. Scenarios describe observable behavior per deliverable: inputs accepted, outputs produced, state changes visible at the deliverable boundary. Steps use domain language. `Domains:` declarations name module paths (the shared import contract with Etch/Realize), and `Requires:`/`Provides:` declare data contracts between deliverables — but scenario steps themselves stay at the behavioral level. Implementation decisions (data contract types, function signatures, concrete data shapes) begin at Etch, where the behavioral spec is translated into testable interfaces.

## Sub-stage Ordering

```
Layout.Decompose → Layout.Verify → Layout.Approve
```

### Layout.Decompose

Sequential steps — each depends on the previous:

1. Read all BIDs from `primary.feature`
2. Decompose into `{deliverable}.feature` subspecs with BIDs, `Domains:`, `Requires:`, `Provides:`
3. When a primary scenario requires behavior beyond existing subspecs, add a BID to the appropriate subspec
4. Add `@traces` tags to `primary.feature` (requires steps 2–3 complete)
5. Derive dependency order from `Requires:` declarations (requires step 2 complete)
6. Write subspecs to `tests/features/{feature_id}/`; write `delivery-order.yaml`

**Step 4 is gated on steps 2–3.** The `@traces` tags reference subspec BIDs — those BIDs exist only after decomposition.

### Layout.Verify

Runs after Layout.Decompose completes. All checks consume the artifacts Decompose just produced:

| Check | Inputs | Mechanical? |
|-------|--------|-------------|
| ANLZ-003 | Primary spec `@traces` + subspec `Domains:` | Yes |
| ANLZ-004 | Primary spec scenarios + subspec BIDs + `@traces` | Partially (effect identification is judgment) |
| ANLZ-005 | Subspec `Requires:` + `Provides:` | Yes |
| ANLZ-006 | Subspec `Requires:` + `Provides:` field hints | Yes |
| Layout inspection | Primary spec BIDs vs. subspec BIDs | Yes (PARTIAL is agent-evaluated) |

On FAIL: show which checks failed; ask user to fix or proceed.

### Layout.Approve

Present subspecs + delivery order + check results. Wait for user gate. On "request changes": revise and re-run Layout.Verify.

## Exit Checks

Machine-verifiable conditions that hold when Layout completes:

### Artifact existence

- [ ] Subspecs exist at `tests/features/{feature_id}/{deliverable}.feature`
- [ ] `delivery-order.yaml` exists at `.haileris/features/{feature_id}/delivery-order.yaml`
- [ ] `layout-inspection.yaml` exists at `.haileris/features/{feature_id}/layout-inspection.yaml`

### BID integrity

- [ ] Every primary spec BID appears in exactly one subspec
- [ ] Every subspec BID traces back to a primary spec entry
- [ ] Every primary scenario has a `@traces` tag
- [ ] Every BID in a `@traces` tag exists in a subspec

### Subspec metadata

- [ ] Every subspec has a `Domains:` declaration
- [ ] Every subspec has a `Provides:` declaration with field hints
- [ ] Every `Requires:` references a `ContractName` satisfied by a `Provides:` in some subspec
- [ ] Each `ContractName` is provided by exactly one subspec
- [ ] The dependency graph (from `Requires:` file references) is acyclic

### Consistency checks

- [ ] ANLZ-003 result recorded
- [ ] ANLZ-004 result recorded
- [ ] ANLZ-005 result recorded
- [ ] ANLZ-006 result recorded
- [ ] Layout inspection recorded with overall result

### Boundary discipline

- [ ] Layout's read scope is `primary.feature` and `constitution.md` only
- [ ] Layout's write scope is `tests/features/{feature_id}/` (subspecs, `@traces`) and `.haileris/features/{feature_id}/` (delivery order, inspection)
- [ ] `@traces` tags are derived from the decomposition mapping — the primary spec and the subspecs Layout just created
