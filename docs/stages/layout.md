# 4. Layout

Decompose the primary spec into ordered delivery subspecs.

## Inputs

- Primary spec (`primary.feature`)
- Constitution

## Process

### Layout.Decompose

1. Read all BIDs from `primary.feature`.
2. Decompose into `{deliverable}.feature` subspecs — per-deliverable behavioral contracts. Each subspec scenario gets a BID tag and a `Domains:` declaration.
3. If a primary scenario requires behavior that falls outside existing subspecs, add a BID to the appropriate subspec. The primary spec drives what BIDs must exist in subspecs.
4. Add `@traces` tags to `primary.feature` — each primary scenario gets a `@traces` tag listing the subspec BIDs it traces through.
5. Determine dependency order among subspecs.
6. Write subspecs to `tests/features/`; write delivery order to `.haileris/features/{feature_id}/delivery-order.yaml`.

### Layout.Verify

1. Run consistency checks (ANLZ-003..004) and BID coverage validation (layout inspection).

#### Consistency Checks (ANLZ-003..004)

| ID | Check |
|----|-------|
| ANLZ-003 | Integration behaviors reference domains listed in the Gherkin spec |
| ANLZ-004 | Subspecs compose into primary spec — every primary scenario's Given/When/Then steps are collectively covered by subspec BIDs (every effect is owned) |

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
  - Subspecs listed in implementation sequence with dependency edges

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Gherkin subspecs | `tests/features/{deliverable}.feature` | Per-deliverable behavioral contracts; must compose into primary spec |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` | Subspecs in implementation order with dependency edges |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | Traceability gate input for Inspect |

## Layout Inspection

Validates subspecs against primary spec BIDs across 5 check types:

| Check | Condition |
|-------|-----------|
| MISSING | A primary spec BID is absent from all subspecs |
| HALLUCINATED | A BID in a subspec has no corresponding primary spec entry |
| DUPLICATED | The same BID is the primary responsibility of more than one subspec |
| INSUFFICIENT | A subspec Feature description is fewer than 10 words, or contains none of the keywords from the BID's Gherkin clauses |
| PARTIAL | A BID is split across subspecs such that neither subspec alone covers its full acceptance criteria |

Overall `pass: true` only when all 5 check types produce zero findings.

On FAIL with `--fix`: up to 2 auto-revision passes; if still failing, escalate to user.

## Subspec Execution Order

Etch and Realize execute **sequentially per subspec** in the dependency order established by Layout:

```
Etch(subspec 1) → Realize(subspec 1) → Etch(subspec 2) → Realize(subspec 2) → ...
```

This ordering ensures later subspecs can depend on earlier subspecs' implementations. The dependency order from Layout determines the sequence. All subspecs must complete before Inspect runs.

## Notes

- Delivery order is committed alongside other feature artifacts — useful for inspecting subspec ordering across retries
- `layout-inspection.yaml` is a Traceability Gate input at Inspect — a missing or failed inspection causes a Critical finding
- The layout inspection can be re-run on demand with `--fix` to attempt auto-repair
- `@traces` tags are authored by Layout during decomposition — they connect primary scenarios to the subspec BIDs created at this stage
- ANLZ-003 and ANLZ-004 run at Layout.Verify, after subspecs and `@traces` tags exist
- `@traces` tag format: `@traces:BID-003,BID-015,BID-024` — lists subspec BIDs the integration scenario traces through
