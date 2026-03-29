# Inspect — Greenfield Construction

## Stage inputs

Everything from stages 1–6. Inspect is the first stage with full read access to all artifacts:

| Artifact | Path | Source |
|----------|------|--------|
| Primary spec | `tests/features/{feature_id}/primary.feature` | Inscribe + Layout |
| Subspecs | `tests/features/{feature_id}/{deliverable}.feature` | Layout |
| Green-phase implementation | `src/` | Realize |
| All tests (passing) | `tests/unit/`, `tests/integration/` | Etch |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | Etch |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | Realize |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` | Harvest |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | Layout |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | Etch |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | Realize |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Project standards | `.haileris/project/standards.md` | Harvest |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Tracks `constitution_version` |

## Stage outputs

| Artifact | Path |
|----------|------|
| Verify report | `.haileris/features/{feature_id}/verify_{timestamp}.md` |

Inspect writes exactly one file. It is a read-only review — source code, test files, spec files, maps, and inspection artifacts are all untouched.

## Components to implement

### 1. Constitution version checker (Inspect.Gate)

Implement a component that compares the current constitution file's version against `constitution_version` recorded in `pipeline-state.yaml`. When the version changed, warn the user and offer to re-run from Inscribe or continue with the original version.

Defined in [traceability-gate.md](../../automation/traceability-gate.md) (constitution version check).

### 2. Traceability gate (Inspect.Gate)

Implement the traceability gate defined in [traceability-gate.md](../../automation/traceability-gate.md). Tier 1 (fully mechanical). Verifies all four inspection artifacts exist and have `pass: true`:

| Artifact | Missing = | `pass: false` = |
|----------|-----------|-----------------|
| `harvest-inspection.yaml` | Critical | Critical with finding count |
| `layout-inspection.yaml` | Critical | Critical with finding count |
| `etch-inspection.yaml` | Critical | Critical with finding count |
| `realize-inspection.yaml` | Critical | Critical with finding count |

Critical traceability findings cause FAIL status and appear at the top of the report.

### 3. Review dimensions (Inspect.Review)

Implement five review dimensions. These run in parallel (no dependencies between them):

#### Standards compliance review
Implement a review that checks production code and tests against project standards (`standards.md`) and pipeline defaults. Constitution violations are Critical severity.

#### Architecture review
Implement a review that validates domain boundaries against BID ownership. Checks for README existence in key directories and API boundary type usage.

#### Complexity and scope review
Implement a review that traces every abstraction back to a BID. Scope creep (code not traceable to any BID) is High severity. Over-engineering (unnecessary complexity for a BID's requirements) is Medium severity.

#### Mutation testing engine
Implement the BID-targeted mutation generator, executor, and kill-rate reporter defined in [mutation-testing.md](../../automation/mutation-testing.md). Tier 2 (M-c): mechanical when standard mutation operators, realize-map, etch-map, and a test runner are available.

Five operator categories: boundary conditions, comparison operators, argument order, branch logic, return values. Surviving mutations are Medium findings. This dimension always runs — it is the only one that validates behavioral correctness against the spec.

#### Interface contract compliance review
Implement a review that validates `Provides:`/`Requires:` implementations against their declarations. Missing or malformed implementations are High severity.

### 4. Finding synthesizer (Inspect.Synthesize)

Implement a component that:
1. Merges and deduplicates findings from all review dimensions, ordered by severity: Critical → High → Medium → Low → Nit
2. Tags each finding with `resolution_domain`: `impl` (fix in production code), `test` (fix in test files), or `spec` (fix a Gherkin spec ambiguity)
3. Determines overall status: any Critical, High, or Medium → **FAIL**; Low/Nit only or zero findings → **PASS**
4. Writes `verify_{timestamp}.md`

## Orchestration

**Sub-stage ordering:** Gate (constitution version check + traceability gate) → Review (5 dimensions in parallel) → Synthesize.

**State transition:** On completion, advance pipeline state to Settle. Inspect always advances regardless of PASS/FAIL — Settle handles findings.

## Scope boundaries

- Inspect writes `verify_{timestamp}.md` only
- Source code, test files, spec files, maps, and inspection artifacts are all untouched
- Inspect is a read-only review — zero changes beyond the report

## Criteria reference

[Inspect correctness criteria](../criteria/inspect.md)
