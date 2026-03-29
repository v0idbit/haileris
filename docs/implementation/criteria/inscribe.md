# Inscribe — Correctness Criteria

## Input Manifest

### Available at Inscribe entry

| Artifact | Path | Source |
|----------|------|--------|
| Improved decomposition | `.haileris/features/{feature_id}/decomposition.md` | Updated by Ascertain |
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` | Written by Ascertain |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Written by Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Shows `ascertain: passed` |

### Artifacts created by this stage

| Artifact | Path | Sub-stage |
|----------|------|-----------|
| Primary spec | `tests/features/{feature_id}/primary.feature` | Inscribe.Author |

Inscribe produces exactly one file. Subspecs, `@traces` tags, delivery order, and subspec metadata (`Domains:`, `Requires:`, `Provides:`) are all Layout's responsibility.

### Read scope

Inscribe reads `decomposition.md`, `ascertainments.md`, `technical-details.md`, and `constitution.md`.

### Write scope

Inscribe writes one file: `tests/features/{feature_id}/primary.feature`. Implementation directories (`src/`, `tests/unit/`, `tests/integration/`) are downstream stages' responsibility.

## Behavioral Constraints

### What Inscribe produces

`primary.feature` contains:
- Feature-level tags: `@status:approved` and `@type:greenfield` (or `modification`/`refactor`)
- End-to-end workflow scenarios, each with a `@BID-NNN` tag
- Standard Gherkin: Given/When/Then steps
- BID tags and status/type metadata only — subspec-specific metadata belongs to Layout

### Behavioral level

Gherkin scenarios describe observable behavior: user actions, system responses, and state changes visible at the feature boundary. Steps use domain language ("When the user submits the form") rather than implementation language ("When the controller calls the service"). The spec is a behavioral contract — Etch translates it into concrete implementation decisions (data contract types, function signatures, fixture shapes), and Realize writes production code to satisfy those decisions.

### BID assignment

- Format: `BID-{NNN}`, sequentially numbered from `001`
- Every Scenario carries exactly one BID
- BIDs are assigned here and remain stable from this point forward

### Status lifecycle

`@status:inscribing` → `@status:ascertaining` (when NEEDS ASCERTAINMENT markers exist) → `@status:approved` (after user gate)

### Constitution violations

Always **Critical** severity. When a constitution exists, Inscribe checks all scenarios against it.

## Sub-stage Ordering

```
Inscribe.Author → Inscribe.Verify → Inscribe.Approve
```

### Inscribe.Author

1. Write `primary.feature` with end-to-end workflow scenarios; assign BIDs
2. Read constitution when present; flag violations
3. Write `primary.feature` to `tests/features/{feature_id}/`

### Inscribe.Verify

Run consistency checks (ANLZ-001..002):

| Check | What it validates |
|-------|-------------------|
| ANLZ-001 | All behaviors are mutually consistent (contradicting BIDs = FAIL) |
| ANLZ-002 | All behaviors comply with project standards |

On FAIL: show which checks failed; ask user to fix or proceed.

### Inscribe.Approve

Present primary spec + check results. Wait for user gate:
- **Approve** — set `@status:approved`; proceed to Layout
- **Request changes (minor)** — edit in place; re-run Inscribe.Verify; present again
- **Request changes (needs ascertainment)** — set `@status:ascertaining`; return to Ascertain

## Exit Checks

### Artifact existence

- [ ] `primary.feature` exists at `tests/features/{feature_id}/primary.feature`

### Content integrity

- [ ] Every scenario has exactly one `@BID-NNN` tag
- [ ] BIDs are sequentially numbered from `001` with consistent numbering
- [ ] Feature-level `@status:approved` tag is present
- [ ] Feature-level `@type:` tag is present (`greenfield`, `modification`, or `refactor`)
- [ ] All scenarios use standard Gherkin (Given/When/Then)

### Consistency checks

- [ ] ANLZ-001 result recorded (or user acknowledged FAIL)
- [ ] ANLZ-002 result recorded (or user acknowledged FAIL)

### Boundary discipline

- [ ] Inscribe produced exactly one file: `primary.feature`
- [ ] Primary spec contains BID tags and status/type metadata only — subspec-specific metadata (`Domains:`, `Requires:`, `Provides:`, `@traces`) belongs to Layout
- [ ] Implementation directories (`src/`, `tests/unit/`, `tests/integration/`) are untouched
