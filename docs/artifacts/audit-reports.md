# Inspection Reports

Machine-readable YAML files produced at validation gates throughout the pipeline. Each inspection report checks a specific artifact for traceability completeness. Together they form the evidence trail that Inspect's Traceability Gate evaluates before reviews begin.

## The Four Inspection Reports

| Artifact | Produced By | Checks |
|---|---|---|
| `harvest-inspection.yaml` | Harvest | decomposition.md and technical-details.md across 4 dimensions: decomposition template compliance, technical details template compliance, artifact preflight, dependency doc coverage |
| `layout-inspection.yaml` | Layout | Task list vs. spec BIDs: MISSING, HALLUCINATED, DUPLICATED, INSUFFICIENT, PARTIAL |
| `etch-inspection.yaml` | Etch | etch-map.yaml BID → test mapping: MISSING, HALLUCINATED, DUPLICATED, INSUFFICIENT, PARTIAL |
| `realize-inspection.yaml` | Realize | Implementation vs. spec BIDs: Completeness, Scope, Broken refs |

## Inspection Check Types

**Layout and etch inspections (5 types):**
- `MISSING` — BID in spec but absent from the artifact
- `HALLUCINATED` — entry in artifact with no matching BID in spec
- `DUPLICATED` — same BID covered by multiple conflicting entries
- `INSUFFICIENT` — coverage exists but does not fully address the behavior
- `PARTIAL` — BID partially covered; some sub-conditions unaddressed

**Realize inspection (3 checks):**
- `Completeness` — every BID maps to at least one source symbol
- `Scope` — no unmapped symbols exist in impl files (AST-checked)
- `Broken refs` — no ghost symbols in the realize-map (symbol path exists and is importable)

## Traceability Gate

All four of `harvest-inspection.yaml`, `layout-inspection.yaml`, `etch-inspection.yaml`, and `realize-inspection.yaml` must exist and pass before reviews begin. A missing or failing inspection is a gate blocker.

## Paths

`.haileris/features/{feature_id}/harvest-inspection.yaml`
`.haileris/features/{feature_id}/layout-inspection.yaml`
`.haileris/features/{feature_id}/etch-inspection.yaml`
`.haileris/features/{feature_id}/realize-inspection.yaml`

## Committed

Yes. All inspection reports are committed as part of the feature's inspection trail.
