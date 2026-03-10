# HAILERIS

A spec-driven pipeline. Takes raw feature context as input; produces verified, green-phase implementation as output.

## Pipeline

Eight stages in sequence. Stages 5–6 repeat per spec subset; the loop between 8 and 2 repeats until no failures remain.

| # | Stage | What it does |
|---|-------|-------------|
| 1 | **Harvest** | Ingest all feature context; synthesize into a Decomposition and Technical Details |
| 2 | **Ascertain** | Surface and resolve ambiguities in the Decomposition |
| 3 | **Inscribe** | Write the behavioral spec (BIDs in Gherkin format) |
| 4 | **Layout** | Break the spec into ordered, non-overlapping implementation tasks |
| 5 | **Etch** | Generate red-phase (failing) tests per spec subset |
| 6 | **Realize** | Implement minimum code to turn red tests green |
| 7 | **Inspect** | Review the finished implementation against the spec |
| 8 | **Settle** | Fix failures by domain; loop back to Ascertain if any remain |

See [`docs/pipeline.md`](docs/pipeline.md) for the full input/output spec and [`docs/diagrams/diagrams.md`](docs/diagrams/diagrams.md) for stage flow and artifact maps.

## Artifacts

Each stage produces artifacts that downstream stages consume. Key artifacts and their paths:

| Artifact | Stage | Path |
|----------|-------|------|
| Decomposition | Harvest | `.haileris/features/{id}/decomposition.md` |
| Technical details | Harvest | `.haileris/features/{id}/technical-details.md` |
| Ascertainments | Ascertain | `.haileris/features/{id}/ascertainments.md` |
| Spec | Inscribe | `.haileris/features/{id}/{feature_name}.feature` |
| Task list | Layout | `.haileris/features/{id}/tasks.md` |
| Red-phase tests | Etch | `tests/` (repo) |
| Etch map | Etch | `.haileris/features/{id}/etch-map.yaml` |
| Green-phase implementation | Realize | `src/` (repo) |
| Realize map | Realize | `.haileris/features/{id}/realize-map.yaml` |
| Implementation failure details | Inspect | `.haileris/features/{id}/verify_{ts}.md` |

Shared project memory:

```
.haileris/memory/
├── standards.md
├── test-conventions.md
└── constitution.md
```

## Auditing

Stages 1, 4, 5, and 6 each produce an audit artifact. All four converge at Inspect as the **Traceability Gate** — a missing or failed audit triggers a Critical finding before reviews begin.

| Inspection artifact | Produced by | Validates |
|---------------------|------------|-----------|
| `harvest-inspection.yaml` | Harvest | decomposition.md and technical-details.md across 4 dimensions |
| `layout-inspection.yaml` | Layout | Task list BID coverage (5 check types) |
| `etch-inspection.yaml` | Etch | etch-map.yaml BID → test mapping (5 check types) |
| `realize-inspection.yaml` | Realize | Realize map: completeness, scope, broken refs |

## Inspect Status Rules

| Findings | Status |
|----------|--------|
| Any Critical or High | FAIL |
| Medium / Low / Nit only | APPROVED WITH SUGGESTIONS |
| None | APPROVED |

Findings are classified by resolution domain: `impl` (production code), `test` (test structure), or `spec` (spec ambiguity). Settle routes each finding to the appropriate fix approach.

## Docs

- [`docs/pipeline.md`](docs/pipeline.md) — stage inputs, outputs, and flow
- [`docs/diagrams/diagrams.md`](docs/diagrams/diagrams.md) — mermaid diagrams: stage flow, artifact paths, traceability gate
- [`docs/stages/`](docs/stages/) — per-stage process, artifacts, and audit details
