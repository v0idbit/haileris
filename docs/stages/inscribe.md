# 3. Inscribe

Create the Gherkin spec from the improved decomposition.

## Inputs

- Improved decomposition
- Constitution

## Process

### Inscribe.Author

1. Produce a behavioral Gherkin spec with BIDs; read constitution if present; flag constitution violations; write to `.haileris/features/{feature_id}/spec/`

### Inscribe.Verify

1. Run read-only consistency checks (ANLZ-001..005)

#### Consistency Checks (ANLZ-001..005)

| ID | Check |
|----|-------|
| ANLZ-001 | No internal contradictions between behaviors |
| ANLZ-002 | No conflicts with existing code (modification/refactor Gherkin specs) |
| ANLZ-003 | No conflicts with project standards |
| ANLZ-004 | Gherkin Given preconditions are achievable (no impossible states) |
| ANLZ-005 | Integration behaviors reference modules listed in the Gherkin spec |

If any check returns FAIL: show which checks failed; ask user to fix or proceed anyway.

### Inscribe.Approve

1. Present Gherkin spec + consistency check results to user; wait for approval
2. Update Gherkin spec frontmatter `status: approved` (or `status: ascertaining` if user requests changes; return to Ascertain)

## Outputs

- Gherkin spec
  - Enumerated behavior tests (BIDs)
  - Delivery details per BID as needed
- Technical details
  - Common details across BIDs
  - Per BID details as needed

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Gherkin spec | `.haileris/features/{feature_id}/spec/` | Source of truth for all downstream stages (Layout through Settle) |

## Notes

- BID format: `BID-{NNN}` (sequentially numbered, e.g. `BID-001`)
- Gherkin spec status lifecycle: `inscribing` → `ascertaining` (if markers exist) → `approved` (after user gate)
- `spec/` is the central artifact — every downstream stage reads it. It must not be modified after user approval
- Constitution violations are always **Critical** severity
- Gherkin spec types: `greenfield` (all new), `modification` (unchanged / modified / new sections), `refactor` (behaviors must not change)