# Inspect — Correctness Criteria

## Input Manifest

### Available at Inspect entry

| Artifact | Path | Source |
|----------|------|--------|
| Primary spec | `tests/features/{feature_id}/primary.feature` | Written by Inscribe, `@traces` added by Layout |
| Subspecs | `tests/features/{feature_id}/{deliverable}.feature` | Written by Layout |
| Green-phase implementation | `src/` | Written by Realize |
| All tests (passing) | `tests/unit/`, `tests/integration/` | Written by Etch |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | Written by Etch |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | Written by Realize |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Project standards | `.haileris/project/standards.md` | Written by Harvest |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Shows `realize: passed` |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` | Written by Harvest |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | Written by Layout |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | Written by Etch |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | Written by Realize |

Inspect is the first stage where every upstream artifact is available. All spec files, tests, source code, maps, and inspections are present.

### Artifacts created by this stage

| Artifact | Path |
|----------|------|
| Verify report | `.haileris/features/{feature_id}/verify_{timestamp}.md` |

### Read scope

Inspect reads everything produced by stages 1–6. This is the only stage with full read access to all artifacts.

### Write scope

Inspect writes exactly one file: `verify_{timestamp}.md`. Inspect is a read-only review of all upstream artifacts — its sole output is the verify report.

## Behavioral Constraints

### Constitution version check

Before reviews begin, verify the constitution version matches the version recorded in `pipeline-state.yaml` at Harvest. When the version has changed, warn the user and offer to re-run from Inscribe or continue with the original version.

### Traceability Gate (Inspect.Gate)

Runs before any reviews. Verifies all four inspection artifacts exist and passed:

| Artifact | Missing = | `pass: false` = |
|----------|-----------|-----------------|
| `harvest-inspection.yaml` | Critical | Critical with finding count |
| `layout-inspection.yaml` | Critical | Critical with finding count |
| `etch-inspection.yaml` | Critical | Critical with finding count |
| `realize-inspection.yaml` | Critical | Critical with finding count |

Critical traceability findings cause FAIL status and appear at the top of the report.

### Finding classification

Each finding receives:
- **Severity:** Critical → High → Medium → Low → Nit
- **Resolution domain:** `impl` (production code), `test` (test files), `spec` (Gherkin spec ambiguity)

Constitution violations are always Critical.

### Status rules

| Finding severity | Overall status |
|-----------------|----------------|
| Any Critical, High, or Medium | **FAIL** |
| Low / Nit only | **PASS** |
| Zero findings | **PASS** |

## Sub-stage Ordering

```
Inspect.Gate → Inspect.Review (parallel) → Inspect.Synthesize
```

### Inspect.Gate

1. Constitution version check
2. Traceability Gate — verify all four inspections exist and passed

### Inspect.Review

All reviews run in parallel:

| Review | Focus |
|--------|-------|
| Standards compliance | Code vs. project standards and pipeline defaults; constitution violations = Critical |
| Architecture review | Domain boundaries vs. BIDs; README existence; API boundary types |
| Complexity and scope | Abstraction traceability to BIDs; scope creep = High, over-engineering = Medium |
| Mutation testing | Targeted mutations per BID; surviving mutation = Medium finding |
| Interface contract compliance | `Provides:`/`Requires:` implementations; missing/malformed = High |

Mutation testing always runs — it is the only dimension that validates behavioral correctness against the spec.

### Inspect.Synthesize

1. Merge and deduplicate findings by severity
2. Tag each finding with `resolution_domain`
3. Determine overall status; write `verify_{timestamp}.md`

## Exit Checks

### Artifact existence

- [ ] `verify_{timestamp}.md` exists at `.haileris/features/{feature_id}/`

### Report completeness

- [ ] Traceability Gate results are recorded (all four inspections checked)
- [ ] All five review dimensions have results
- [ ] Every finding has a severity and `resolution_domain`
- [ ] Overall status is determined (PASS or FAIL)

### Report retention

- [ ] Report is timestamped (preserving prior reports from earlier Settle loops)
- [ ] Prior verify reports are retained for audit

### Boundary discipline

- [ ] Inspect's write scope is `.haileris/features/{feature_id}/verify_{timestamp}.md` only
- [ ] Source code, test files, spec files, maps, and inspection artifacts are all untouched
- [ ] Inspect produced the verify report and made zero other changes
