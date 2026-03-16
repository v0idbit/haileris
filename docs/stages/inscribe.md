# 3. Inscribe

Create the Gherkin spec from the improved decomposition.

## Inputs

- Improved decomposition
- Constitution

## Process

### Inscribe.Author

1. Write `primary.feature` — end-to-end workflow scenarios covering the feature's observable behavior. Each scenario gets a BID tag and a `@traces` tag listing the subspec BIDs it will trace through.
2. Decompose into concern subspecs (`{concern}.feature`) — unit-level behavioral contracts. Each subspec scenario gets a BID tag.
3. If a primary scenario requires behavior no subspec covers, add a BID to the appropriate subspec. The primary spec drives what BIDs must exist in subspecs.
4. Read constitution if present; flag constitution violations.
5. Write all feature files to `tests/features/`.

### Inscribe.Verify

1. Run read-only consistency checks (ANLZ-001..006)

#### Consistency Checks (ANLZ-001..006)

| ID | Check |
|----|-------|
| ANLZ-001 | No internal contradictions between behaviors |
| ANLZ-002 | No conflicts with existing code (modification/refactor Gherkin specs) |
| ANLZ-003 | No conflicts with project standards |
| ANLZ-004 | Gherkin Given preconditions are achievable (no impossible states) |
| ANLZ-005 | Integration behaviors reference modules listed in the Gherkin spec |
| ANLZ-006 | Subspecs compose into primary spec — every primary scenario's Given/When/Then steps are collectively covered by subspec BIDs (no unowned data transformations) |

If any check returns FAIL: show which checks failed; ask user to fix or proceed anyway.

##### ANLZ-006: Composition Validation

For each primary spec scenario:
1. Verify the scenario has a `@traces` tag listing subspec BIDs
2. Verify all referenced BIDs exist in subspecs
3. Identify the data transformations required by the scenario's steps
4. Verify each transformation is covered by a referenced subspec BID

Gap = a transformation step with no covering subspec BID. On FAIL: show which primary scenarios have uncovered steps.

### Inscribe.Approve

1. Present Gherkin spec + consistency check results to user; wait for user gate (APPROVE / REJECT)
2. Update Gherkin spec frontmatter `status: approved` (or `status: ascertaining` if user requests changes; return to Ascertain)

## Outputs

- Primary spec
  - End-to-end workflow scenarios (BIDs with `@traces` tags)
- Gherkin subspecs
  - Per-concern behavioral scenarios (BIDs)
  - Delivery details per BID as needed
- Technical details
  - Common details across BIDs
  - Per BID details as needed

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Primary spec | `tests/features/primary.feature` | Integration-level workflow scenarios; drives subspec completeness |
| Gherkin subspecs | `tests/features/{concern}.feature` | Unit-level behavioral contracts; must compose into primary spec |

## Notes

- BID format: `BID-{NNN}` (sequentially numbered, e.g. `BID-001`)
- Gherkin spec status lifecycle: `inscribing` → `ascertaining` (if markers exist) → `approved` (after user gate)
- Authoring order: primary spec first, then subspecs — the primary spec drives what BIDs must exist
- `@traces` tag format: `@traces:BID-003,BID-015,BID-024` — lists subspec BIDs the integration scenario traces through
- `tests/features/` is the canonical location for all `.feature` files — every downstream stage reads them. They must not be modified after user approval
- Constitution violations are always **Critical** severity
- Gherkin spec types: `greenfield` (all new), `modification` (unchanged / modified / new sections), `refactor` (behaviors must not change)
