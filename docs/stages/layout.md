# 4. Layout

Decompose the primary spec into ordered delivery subspecs.

## Inputs

- Primary spec (`primary.feature`)
- Constitution

## Process

### Layout.Decompose

1. Read all BIDs from `primary.feature`.
2. Decompose into `{deliverable}.feature` subspecs — per-deliverable behavioral contracts. Each subspec scenario gets a BID tag and a `Domains:` declaration and `Requires:`/`Provides:` declarations.
3. If a primary scenario requires behavior that falls outside existing subspecs, add a BID to the appropriate subspec. The primary spec drives what BIDs must exist in subspecs.
4. Add `@traces` tags to `primary.feature` — each primary scenario gets a `@traces` tag listing the subspec BIDs it traces through.
5. Dependency order is derived from `Requires:` declarations. Each `Requires: {file}.feature -> {ContractName}` implies a dependency on `{file}.feature`. A subspec with no `Requires:` is a root node.
6. Write subspecs to `tests/features/{feature_id}/`; compile `delivery-order.yaml` from subspec `Requires:` and `Provides:` declarations to `.haileris/features/{feature_id}/delivery-order.yaml`.

### Layout.Verify

1. Run consistency checks (ANLZ-003..006) and BID coverage validation (layout inspection).

#### Consistency Checks (ANLZ-003..006)

| ID | Check |
|----|-------|
| ANLZ-003 | Integration behaviors reference domains listed in the Gherkin spec |
| ANLZ-004 | Subspecs compose into primary spec — every primary scenario's When/Then steps (effects only) are collectively covered by subspec BIDs (every effect is owned) |
| ANLZ-005 | Interface contract consistency — every `Requires:` is satisfied by a `Provides:`; no cycles; no duplicate Provides |
| ANLZ-006 | Field hint completeness — every `Provides:` has field hints; every `Requires:` field set is a subset of the corresponding `Provides:` fields |

If any check returns FAIL: show which checks failed; ask user to fix or proceed anyway.

##### ANLZ-003: Domain Coverage

Fully mechanical. Parsing and set operations only.

1. Parse each subspec's `Domains:` line → set of declared domain paths per subspec. A subspec with no `Domains:` line = FAIL.
2. Parse each primary scenario's `@traces` tag → set of referenced subspec BIDs.
3. Resolve each referenced BID to its parent subspec file.
4. Collect the declared domains from those parent subspecs.
5. Verify every referenced subspec has declared domains. A primary scenario tracing through a subspec with no `Domains:` declaration = FAIL.

##### ANLZ-004: Composition Validation

For each primary spec scenario:
1. Verify the scenario has a `@traces` tag listing subspec BIDs
2. Verify all referenced BIDs exist in subspecs
3. Identify the effects required by the scenario's steps. An effect is any observable consequence of a step: state created, state changed, data passed between deliverables, or output produced. Only steps that produce observable consequences count as effects; Given preconditions restating already-covered state are context, and context is excluded.
4. Verify each effect is covered by a referenced subspec BID

Every effect must have a covering subspec BID. An uncovered effect = gap. On FAIL: show which primary scenarios have uncovered steps.

##### ANLZ-005: Interface Contract Consistency

Fully mechanical. Parsing and set operations only.

1. Parse each subspec's `Requires:` and `Provides:` lines.
2. Collect all Provides ContractNames across all subspecs.
3. For each Requires entry, verify the referenced ContractName exists in the Provides set.
4. Verify the referenced source file in each Requires entry exists as a subspec.
5. Verify no two subspecs Provide the same ContractName.
6. Build the dependency graph from Requires file references; verify acyclic.

##### ANLZ-006: Field Hint Completeness

Fully mechanical. Parsing and set operations only.

1. Parse each `Provides:` entry; extract the field hint list from the parenthetical — identifiers before the em dash (`—` or `---`), comma-separated.
2. A `Provides:` entry with no field hints (no parenthetical, no em dash, or nothing before the em dash) = FAIL.
3. Parse each `Requires:` entry; extract the field hint list from the parenthetical using the same format.
4. For each `Requires:` with field hints, look up the corresponding `Provides:` by ContractName; verify the `Requires:` fields are a subset of the `Provides:` fields. A field in `Requires:` absent from the corresponding `Provides:` = FAIL. A `Requires:` with no field hints = PASS (advisory; the consumer accepts the full contract).

Note: ANLZ-006 does not validate ContractName resolution — that is ANLZ-005's concern. If a `Requires:` references a ContractName not found in any `Provides:`, ANLZ-006 skips the subset check for that entry (ANLZ-005 will report the failure).

2. Write `layout-inspection.yaml` to `.haileris/features/{feature_id}/`.

### Layout.Approve

1. Present subspecs + delivery order + consistency check results to user; wait for user gate:
   - **Approve** — proceed to Etch
   - **Request changes** — revise subspecs, delivery order, or `@traces`; re-run Layout.Verify; present again

## Outputs

- Gherkin subspecs
  - Per-deliverable behavioral scenarios (BIDs)
  - Delivery details per BID as needed
- Delivery order (`delivery-order.yaml`)
  - Compiled from subspec `Requires:` and `Provides:` declarations. Lists subspecs in topological order with dependency edges and interface contract data.

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Gherkin subspecs | `tests/features/{feature_id}/{deliverable}.feature` | Per-deliverable behavioral contracts; must compose into primary spec |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` | Compiled from subspec Requires/Provides; regenerated by Settle.Scope on re-entry |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | Traceability gate input for Inspect |

## Layout Inspection

Validates subspecs against primary spec BIDs across 5 check types:

| Check | Condition |
|-------|-----------|
| MISSING | A primary spec BID is absent from all subspecs |
| HALLUCINATED | A BID in a subspec has no corresponding primary spec entry |
| DUPLICATED | The same BID is the primary responsibility of more than one subspec |
| INSUFFICIENT | A subspec Feature description is fewer than 10 words, or contains none of the keywords from the BID's Gherkin clauses. `Requires:`, `Provides:`, and `Domains:` lines are excluded from word count and keyword analysis (structural metadata). |
| PARTIAL | A BID is split across subspecs such that neither subspec alone covers its full acceptance criteria |

Overall `pass: true` only when all mechanically verified check types produce zero findings. PARTIAL is agent-evaluated (no mechanical verification; inspection records SKIP).

On FAIL with `--fix`: up to `inspection_fixes` auto-revision passes (see [pipeline config](../artifacts/config.md); default: 0); if still failing or fixes exhausted, escalate to user.

## Subspec Execution Order

Etch and Realize execute **per subspec**, respecting the dependency edges established by Layout. The correctness requirement: a subspec's Etch/Realize cycle runs only after all subspecs it `Requires:` have completed their Realize pass.

**Sequential (default strategy):**

```
Etch(subspec 1) → Realize(subspec 1) → Etch(subspec 2) → Realize(subspec 2) → ...
```

Sequential execution is the simplest valid strategy and keeps the agent's working set focused on one subspec at a time.

**Parallel (independent subspecs):**

Subspecs with no dependency relationship (no `Requires:` path between them) may execute their Etch/Realize cycles concurrently. The dependency graph in `delivery-order.yaml` identifies which subspecs are independent. Subspecs at the same topological level share no edges and can run in parallel.

```
Etch(A) → Realize(A) ─┐
                       ├→ Etch(C) → Realize(C) → ...
Etch(B) → Realize(B) ─┘
```

In this example, A and B are independent roots; C `Requires:` both A and B.

All subspecs must complete before the final integration Etch pass and before Inspect runs.

## Notes

- Delivery order is committed alongside other feature artifacts — useful for inspecting subspec ordering across retries
- `layout-inspection.yaml` is a Traceability Gate input at Inspect — a missing or failed inspection causes a Critical finding
- The layout inspection can be re-run on demand with `--fix` to attempt auto-repair
- `@traces` tags are authored by Layout during decomposition — they connect primary scenarios to the subspec BIDs created at this stage
- ANLZ-003, ANLZ-004, ANLZ-005, and ANLZ-006 run at Layout.Verify, after subspecs and `@traces` tags exist
- ANLZ-006 complements ANLZ-005: ANLZ-005 validates contract name resolution and graph structure; ANLZ-006 validates field-level completeness within those contracts
- `@traces` tag format: `@traces:BID-003,BID-015,BID-024` — lists subspec BIDs the integration scenario traces through
- `delivery-order.yaml` is a derived artifact compiled from subspec `Requires:` and `Provides:` declarations. Regenerated by Settle.Scope when a Settle loop is initiated.
- `Requires:` implies the dependency edge — there is no separate `Depends-on:` mechanism.
