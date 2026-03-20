# HAILERIS

A spec-driven pipeline. Takes raw feature context as input; produces verified, green-phase implementation as output.

## Pipeline

Eight stages in sequence. Stages 5–6 repeat per subspec (sequentially: Etch→Realize per subspec). After Settle, remaining failures loop to the earliest stage required by domain: `spec` → Ascertain, `test` → Etch, `impl` → Realize.

| # | Stage | What it does |
|---|-------|-------------|
| 1 | **Harvest** | Ingest all feature context; synthesize into a Decomposition and Technical Details |
| 2 | **Ascertain** | Surface and resolve ambiguities in the Decomposition |
| 3 | **Inscribe** | Write the primary spec: end-to-end workflow scenarios with BIDs |
| 4 | **Layout** | Decompose the primary spec into ordered delivery subspecs |
| 5 | **Etch** | Generate red-phase (failing) tests per subspec |
| 6 | **Realize** | Implement minimum code to turn red tests green |
| 7 | **Inspect** | Review the finished implementation against the spec |
| 8 | **Settle** | Fix failures by domain; loop to earliest required stage if any remain |

> Harvest, Inscribe, Layout, Inspect, and Settle each contain named sub-stages (e.g., `Harvest.Explore → Harvest.Synthesize → Harvest.Validate → Harvest.Initialize`). See individual stage docs for details.

See [`docs/pipeline.md`](docs/pipeline.md) for the full input/output spec and [`docs/diagrams/diagrams.md`](docs/diagrams/diagrams.md) for stage flow and artifact maps.

## Artifacts

Each stage produces artifacts that downstream stages consume. Key artifacts and their paths:

| Artifact | Stage | Path |
|----------|-------|------|
| Decomposition | Harvest | `.haileris/features/{feature_id}/decomposition.md` |
| Technical details | Harvest | `.haileris/features/{feature_id}/technical-details.md` |
| Ascertainments | Ascertain | `.haileris/features/{feature_id}/ascertainments.md` |
| Primary spec | Inscribe | `tests/features/primary.feature` |
| Subspecs | Layout | `tests/features/{deliverable}.feature` |
| Delivery order | Layout | `.haileris/features/{feature_id}/delivery-order.yaml` |
| Red-phase tests | Etch | `tests/` (repo) |
| Etch map | Etch | `.haileris/features/{feature_id}/etch-map.yaml` |
| Green-phase implementation | Realize | `src/` (repo) |
| Realize map | Realize | `.haileris/features/{feature_id}/realize-map.yaml` |
| Implementation failure details | Inspect | `.haileris/features/{feature_id}/verify_{timestamp}.md` |
| Pipeline state | Harvest | `.haileris/features/{feature_id}/pipeline-state.yaml` |

Project-wide artifacts:

```
.haileris/project/
├── standards.md
├── test-conventions.md
├── constitution.md
└── last-harvest.json
```

## Inspecting

Stages 1, 4, 5, and 6 each produce an inspection artifact. All four converge at Inspect as the **Traceability Gate** — a missing or failed inspection artifact triggers a Critical finding before reviews begin.

| Inspection artifact | Produced by | Validates |
|---------------------|------------|-----------|
| `harvest-inspection.yaml` | Harvest | decomposition.md and technical-details.md across 4 dimensions |
| `layout-inspection.yaml` | Layout | Subspec BID coverage (5 check types; 4 active, 1 deferred) |
| `etch-inspection.yaml` | Etch | etch-map.yaml BID → test mapping (5 check types; 3 active, 2 deferred) |
| `realize-inspection.yaml` | Realize | Realize map: completeness, scope (deferred), broken refs |

## Inspect Status Rules

| Findings | Status |
|----------|--------|
| Any Critical, High, or Medium | FAIL |
| Low / Nit only, or none | PASS |

Findings are classified by resolution domain: `impl` (production code), `test` (test structure), or `spec` (spec ambiguity). Settle routes each finding to the appropriate fix approach.

## Docs

- [`docs/pipeline.md`](docs/pipeline.md) — stage inputs, outputs, and flow
- [`docs/diagrams/diagrams.md`](docs/diagrams/diagrams.md) — mermaid diagrams: stage flow, artifact paths, traceability gate
- [`docs/stages/`](docs/stages/) — per-stage process, artifacts, and inspect details
- [`docs/artifacts/`](docs/artifacts/) — artifact format and lifecycle specs
- [`docs/automation/`](docs/automation/) — mechanical verification specs (inspections, analysis checks)
