# 7. Inspect

Review each tentatively finished implementation against the Gherkin spec.

## Inputs

- Gherkin spec
- Green-phase implementation
- Etch map (`etch-map.yaml`) — BID → test function mapping from Etch
- Realize map (`realize-map.yaml`) — BID → source symbol mapping from Realize
- Constitution

## Process

### Pre-check: Traceability Gate

Before reviews begin, verify all four BID inspection artifacts exist and passed:

| Artifact | Source stage | Failure = |
|----------|-------------|-----------|
| `harvest-inspection.yaml` | Harvest | Critical: "harvest-inspection.yaml not found; context coverage unverified" |
| `layout-inspection.yaml` | Layout | Critical: "layout-inspection.yaml not found; BID coverage for task list unverified" |
| `etch-inspection.yaml` | Etch | Critical: "etch-inspection.yaml not found; test BID mapping unverified" |
| `realize-inspection.yaml` | Realize | Critical: "realize-inspection.yaml not found; build BID mapping unverified" |

If a file exists but `pass: false`, record Critical with the finding count. Critical traceability findings cause FAIL status and appear at the top of the report.

### Step 1: Parallel Review

Shared context (Gherkin spec, Constitution, Standards, pyproject.toml) is loaded once for all reviews.

Run all reviews in parallel:

1. **Standards compliance** — validate code against project standards (project standards first, pipeline defaults second); constitution violations = Critical
2. **Architecture review** — validate module boundaries against Gherkin spec BIDs; check README.md existence; API boundary type checking (Pydantic / dataclass / plain); constitution violations = Critical
3. **Complexity and scope** — evaluate every abstraction for BID traceability; scope creep = HIGH, over-engineering = MEDIUM
4. **Mutation testing** — design 5–10 targeted mutations; report kill rate (optional; skip if disabled)

After all reviews complete, synthesize.

### Step 2: Synthesize and Classify Findings

1. Merge and deduplicate findings by severity: Critical → High → Medium → Low → Nit
2. Tag each finding with a `resolution_domain`:
   - `impl` — fix in production/library code (default)
   - `test` — fix in test files (fixture dedup, assertion patterns, missing assertions from BID Gherkin Then clauses)
   - `spec` — fix a Gherkin spec ambiguity (under-specified or ambiguous BID)
3. Determine overall status and write report to `.haileris/features/{feature_id}/verify_{timestamp}.md`

## Outputs

- Implementation failure details

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Implementation failure details | `.haileris/features/{feature_id}/verify_{timestamp}.md` | Timestamped; ingested by Settle; kept for inspection trail |

## Status Rules

| Finding severity | Overall status |
|-----------------|----------------|
| Any Critical or High | **FAIL** |
| Medium / Low / Nit only | **APPROVED WITH SUGGESTIONS** |
| No findings | **APPROVED** |

## Notes

- Traceability Gate runs before any reviews — inspection artifacts from Harvest, Layout, Etch, and Realize must all pass for a clean Inspect
- Constitution violations are always Critical severity
- Finding `resolution_domain` determines the fix approach in Settle: `impl` → targeted production code fix, `test` → structural test quality fix, `spec` → auto-resolve Gherkin spec ambiguity
- Architecture findings requiring judgment (module restructuring, design pattern changes) are surfaced to the user rather than auto-fixed in Settle