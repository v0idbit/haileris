# Inspection Reports

Machine-readable YAML files produced at validation gates throughout the pipeline. Each inspection report checks a specific artifact for traceability completeness. Together they form the evidence trail that Inspect's Traceability Gate evaluates before reviews begin.

## The Four Inspection Reports

| Artifact | Produced By | Checks |
|---|---|---|
| `harvest-inspection.yaml` | Harvest | decomposition.md and technical-details.md across 4 dimensions: decomposition template compliance, technical details template compliance, artifact preflight, dependency doc coverage |
| `layout-inspection.yaml` | Layout | Subspec vs. primary spec BIDs: MISSING, HALLUCINATED, DUPLICATED, INSUFFICIENT, PARTIAL* |
| `etch-inspection.yaml` | Etch | etch-map.yaml BID → test mapping: MISSING, HALLUCINATED, DUPLICATED*, INSUFFICIENT, PARTIAL* |
| `realize-inspection.yaml` | Realize | Implementation vs. spec BIDs: Completeness, Scope†, Broken refs |

*Agent-evaluated — no mechanical verification; inspection records status: SKIP. See [automation specs](../automation/README.md).
†Constraint-gated — has a mechanical algorithm but requires AST tooling; records SKIP when unavailable.

## Inspection Check Types

**Layout and etch inspections (5 types):**
- `MISSING` — BID in spec but absent from the artifact
- `HALLUCINATED` — entry in artifact with no matching BID in spec
- `DUPLICATED` — same BID covered by multiple conflicting entries
- `INSUFFICIENT` — coverage exists but does not fully address the behavior
- `PARTIAL` — BID partially covered; some sub-conditions unaddressed

Layout PARTIAL, Etch DUPLICATED, and Etch PARTIAL are agent-evaluated. The inspection records SKIP for these checks (no mechanical verification).

**Realize inspection (3 checks):**
- `Completeness` — every BID maps to at least one derivation
- `Scope` — every derivation in impl files maps to a BID (AST-checked)
- `Broken refs` — every derivation in the realize-map resolves to an existing, importable source path

Scope is constraint-gated on AST tooling availability. When unavailable, the inspection records SKIP.

## Traceability Gate

All four of `harvest-inspection.yaml`, `layout-inspection.yaml`, `etch-inspection.yaml`, and `realize-inspection.yaml` must exist and pass before reviews begin. A missing or failing inspection is a gate blocker.

## Paths

`.haileris/features/{feature_id}/harvest-inspection.yaml`
`.haileris/features/{feature_id}/layout-inspection.yaml`
`.haileris/features/{feature_id}/etch-inspection.yaml`
`.haileris/features/{feature_id}/realize-inspection.yaml`

## Committed

Yes. All inspection reports are committed as part of the feature's inspection trail.
